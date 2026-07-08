//
//  HomeViewModel.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import SwiftData
import CloudKit

@Observable
class HomeViewModel {
    // MARK: - Services
    private let tripService = CloudKitTripService()
    private let participantService = CloudKitParticipantService()
    private let inviteService = CloudKitInviteService()
    private let sharingService = CloudKitSharingService()
    private let identityService = CloudKitIdentityService()
    private let zoneService = CloudKitZoneService()
    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let locationService = LocationService()
    private let locationSyncService = CloudKitLocationSyncService()
    private let locationSharingCoordinator: LocationSharingCoordinator
    private let tripStatusViewModel: TripStatusViewModel
    private let liveActivityManager = LiveActivityLifecycleManager()
    private let tripNotificationService = TripNotificationService()
    private let notificationPermissionManager = NotificationPermissionManager()
    private let analytics: AnalyticsLogging = AnalyticsService.shared
    private let etaAccuracySampler = ETAAccuracySampler()
    private var cachedUserID: CKRecord.ID?
    /// Which trip this device currently has `locationSharingCoordinator`
    /// running for — guards `ensureLocationSharing` so it only starts once
    /// per trip instead of restarting every refresh tick.
    private var sharingTripID: CKRecord.ID?

    init() {
        locationSharingCoordinator = LocationSharingCoordinator(
            locationService: locationService,
            syncService: locationSyncService
        )
        tripStatusViewModel = TripStatusViewModel(locationSyncService: locationSyncService)
    }

    // MARK: - Trip Draft

    var createTripDraft = TripDraft()

    // MARK: - Trip and Participant List

    var trips: [Trip] { TripStore.shared.trips }
    var participants: [Participant] { TripStore.shared.participants }
    var loadErrorMessage: String? { TripStore.shared.lastLoadErrorMessage }

    // MARK: - Create Trip Flow

    var nextStepRequest = 0
    var isNextStepEnabled = false

    // MARK: - Navigation / Presentation

    var isInvitationPresented = false
    var isCalendarPresented = false
    var isLocationPresented = false
    var isEditingInvitationDetails = false

    // MARK: - Creation State

    var isSavingTrip = false
    var hasCreatedTrip = false
    var creationErrorMessage: String?
    var lastCreatedTripID: CKRecord.ID?
    var shareURL: String?
    var isCreatingShare = false
    var shareErrorMessage: String?
    var shareAcceptanceErrorMessage: String?

    // MARK: - Trip Lifecycle / Member Management State

    var tripActionErrorMessage: String?
    var isUpdatingTripStatus = false

    // MARK: - Computed Properties
    var canConfirmTripCreation: Bool {
        createTripDraft.canCreateTrip &&
        !isSavingTrip &&
        !hasCreatedTrip
    }

    // MARK: - Actions

    func resetCreateTripFlow() {
        createTripDraft.reset()
        nextStepRequest = 0
        isNextStepEnabled = false

        isInvitationPresented = false
        isCalendarPresented = false
        isLocationPresented = false
        isEditingInvitationDetails = false

        isSavingTrip = false
        hasCreatedTrip = false
        creationErrorMessage = nil
        lastCreatedTripID = nil
        shareURL = nil
        isCreatingShare = false
        shareErrorMessage = nil
    }

    /// NFR-2: instruments the PRD §9 "creation success rate" and "setup time"
    /// metrics over this already-shipped flow — measured from this call's
    /// entry (the user's "confirm" tap) to the point every CloudKit write it
    /// depends on (trip, owner participant, share, invite) has succeeded.
    func confirmTripCreation(using modelContext: ModelContext) async throws -> String {
        guard canConfirmTripCreation else {
            throw CloudKitError.operationFailed
        }

        isSavingTrip = true
        creationErrorMessage = nil
        shareErrorMessage = nil
        shareURL = nil

        defer {
            isSavingTrip = false
        }

        let startedAt = Date()

        do {
            // MARK: - Current User
            let ownerID = try await identityService.currentUserRecordID()

            // MARK: - Invitation Code
            let invitationCode = inviteService.generateInvitationCode()
            createTripDraft.invitationCode = invitationCode

            // MARK: - Query Local Profile
            let descriptor = FetchDescriptor<UserProfile>()
            let localProfile = try? modelContext.fetch(descriptor).first(where: { $0.userID == UserSession.shared.userIdentifier })
            let ownerName = localProfile?.displayName.isEmpty == false ? localProfile?.displayName : UserSession.shared.displayName

            // MARK: - Create Trip
            let trip = Trip(
                id: nil,
                title: createTripDraft.name,
                destination: createTripDraft.locationName,
                startDate: createTripDraft.arrivalDate,
                endDate: createTripDraft.arrivalDate,
                ownerID: ownerID,
                ownerDisplayName: ownerName,
                invitationCode: invitationCode,
                destinationLatitude: createTripDraft.coordinate?.latitude,
                destinationLongitude: createTripDraft.coordinate?.longitude,
                locationAddress: createTripDraft.locationAddress,
                apartmentUnitFloor: createTripDraft.apartmentUnitFloor,
                locationNickname: createTripDraft.locationNickname,
                createdAt: Date(),
                updatedAt: Date()
            )

            let savedTrip = try await tripService.createTrip(trip)

            let tripID = savedTrip.id
            lastCreatedTripID = tripID

            // MARK: - Create Owner Participant
            let ownerParticipant = Participant(
                id: nil,
                tripID: tripID!,
                userID: ownerID,
                displayName: ownerName,
                role: .owner,
                joinedAt: Date(),
                avatarImageData: localProfile?.avatarImageData
            )

            _ = try await participantService.createParticipant(ownerParticipant)

            let (_, generatedShareURL) = try await sharingService.createShare(for: tripID!)

            try await inviteService.publishInvite(
                code: invitationCode,
                shareURL: generatedShareURL
            )
            
            self.shareURL = generatedShareURL.absoluteString

            // MARK: - Refresh Home Data
            await TripStore.shared.loadTrips()

            hasCreatedTrip = true

            analytics.log(.tripCreateSucceeded(setupSeconds: Date().timeIntervalSince(startedAt)))
            return invitationCode
        } catch {
            creationErrorMessage = ErrorHelper.simplify(error)
            throw error
        }
    }

    // MARK: - Join Trip State
    
    var joinPreviewTrip: Trip?

    func acceptShare(from notification: Notification) async {
        guard let metadata = CloudKitShareAcceptanceBridge.metadata(from: notification) else {
            return
        }

        await acceptShare(metadata)
    }

    func acceptShare(from url: URL) async {
        do {
            let tripID = try await joinSharedTrip(from: url)
            let fetchedTrip = try await tripService.fetchSharedTrip(id: tripID)
            await MainActor.run { self.joinPreviewTrip = fetchedTrip }
        } catch {
            debugLog("[CloudKitSharing] Share URL acceptance failed: \(error.localizedDescription)")
        }
    }

    func acceptShare(_ metadata: CKShare.Metadata) async {
        do {
            let tripID = try await joinSharedTrip(metadata)
            let fetchedTrip = try await tripService.fetchSharedTrip(id: tripID)
            await MainActor.run { self.joinPreviewTrip = fetchedTrip }
        } catch {
            debugLog("[CloudKitSharing] Share metadata acceptance failed: \(error.localizedDescription)")
        }
    }

    func previewTrip(invitationCode: String) async throws {
        shareAcceptanceErrorMessage = nil

        let normalizedCode = invitationCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        debugLog("🔍 Looking up invite for preview:", normalizedCode)

        guard let invite = try await inviteService.findInvite(by: normalizedCode) else {
            debugLog("❌ Invite not found")
            throw CloudKitError.invalidInvitation
        }

        debugLog("✅ Invite found")
        debugLog("Share URL:", invite.shareURL.absoluteString)

        do {
            let tripID = try await joinSharedTrip(from: invite.shareURL)
            debugLog("✅ Share accepted for preview")

            let fetchedTrip = try await tripService.fetchSharedTrip(id: tripID)
            
            await MainActor.run {
                self.joinPreviewTrip = fetchedTrip
            }

        } catch {
            debugLog("❌ Share acceptance failed:", error)
            throw error
        }
    }
    
    func confirmJoinTrip(trip: Trip, using modelContext: ModelContext) async throws {
        guard let tripID = trip.id else { return }
        
        let currentUserID = try await identityService.currentUserRecordID()
        let descriptor = FetchDescriptor<UserProfile>()
        let localProfile = try? modelContext.fetch(descriptor).first(where: { $0.userID == UserSession.shared.userIdentifier })
        
        let participant = Participant(
            id: CKRecord.ID(recordName: UUID().uuidString, zoneID: tripID.zoneID),
            tripID: tripID,
            userID: currentUserID,
            displayName: UserSession.shared.displayName,
            role: .member,
            joinedAt: Date(),
            avatarImageData: localProfile?.avatarImageData
        )

        _ = try await participantService.createParticipant(participant)
        debugLog("✅ Participant record created for confirm joiner")

        await TripStore.shared.loadTrips()
    }

    /// NFR-2: instruments the PRD §9 "join success rate" and "setup time"
    /// metrics — measured from share-acceptance start to the point
    /// `CloudKitSharingService.acceptShare` actually succeeds.
    func joinSharedTrip(from url: URL) async throws -> CKRecord.ID {
        shareAcceptanceErrorMessage = nil
        let startedAt = Date()

        do {
            let tripID = try await sharingService.acceptShare(from: url)
            analytics.log(.shareAcceptSucceeded(setupSeconds: Date().timeIntervalSince(startedAt)))
            return tripID
        } catch {
            shareAcceptanceErrorMessage = ErrorHelper.simplify(error)
            throw error
        }
    }

    func joinSharedTrip(_ metadata: CKShare.Metadata) async throws -> CKRecord.ID {
        shareAcceptanceErrorMessage = nil
        let startedAt = Date()

        do {
            let tripID = try await sharingService.acceptShare(metadata)
            analytics.log(.shareAcceptSucceeded(setupSeconds: Date().timeIntervalSince(startedAt)))
            return tripID
        } catch {
            shareAcceptanceErrorMessage = ErrorHelper.simplify(error)
            throw error
        }
    }

    func loadTrips() async {
        await TripStore.shared.loadTrips()
    }

    // MARK: - Current User

    func currentUserID() async throws -> CKRecord.ID {
        if let cachedUserID { return cachedUserID }
        let userID = try await identityService.currentUserRecordID()
        cachedUserID = userID
        return userID
    }

    /// Checks `Participant.role` only — TRIP-2's audit found this used to
    /// also check `trip.ownerID == userID`, but `ownerID` is a CloudKit-level
    /// fact that can never change (see `CloudKitZoneService`/AD-2's
    /// zone-per-owner constraint) while `role` is the actual, reassignable
    /// app-level "owner" concept `reassignOwnershipIfNeeded` promotes into.
    /// Keeping the `ownerID` check would make the original owner permanently
    /// re-qualify as "owner" here even after leaving and being replaced,
    /// disagreeing with every other owner-gated path. Resolved by dropping
    /// the `ownerID` branch entirely; `role` is now the single source of truth.
    func isOwner(of trip: Trip, userID: CKRecord.ID) -> Bool {
        participants.contains {
            $0.tripID == trip.id && $0.userID == userID && $0.role == .owner
        }
    }

    // MARK: - ETA / Live Activity (Sprint 2)

    /// This device's own computed ETA/distance/status for `trip`, once
    /// available — nil until `refreshTripStatus` has run at least once with
    /// a fresh location for the current user.
    func currentUserTripState(for trip: Trip, userID: CKRecord.ID) -> ParticipantTripState? {
        tripStatusViewModel.participantStates[userID]
    }

    /// Recomputes every participant's ETA/distance/status (ETA-1/ETA-2) for
    /// `trip` and pushes the aggregated result into the Live Activity
    /// (ETA-3/ETA-4). Call this whenever new location data is expected —
    /// LOC-1's sync tick/subscription fire — not from an independent fixed
    /// timer.
    func refreshTripStatus(for trip: Trip, isBackgrounded: Bool = false) async {
        guard trip.status == .active,
              let tripID = trip.id,
              let destination = trip.destinationCoordinate else { return }

        await ensureLocationSharing(for: trip)

        let previousStates = tripStatusViewModel.participantStates
        await tripStatusViewModel.refresh(tripID: tripID, destination: destination, isBackgrounded: isBackgrounded)
        etaAccuracySampler.recordTransitions(previous: previousStates, updated: tripStatusViewModel.participantStates)

        let states = Array(tripStatusViewModel.participantStates.values)
        let displayNames = Dictionary(
            uniqueKeysWithValues: participants
                .filter { $0.tripID == tripID }
                .compactMap { participant -> (CKRecord.ID, String)? in
                    guard let displayName = participant.displayName else { return nil }
                    return (participant.userID, displayName)
                }
        )

        let userID = try? await currentUserID()
        if let userID {
            tripNotificationService.notifyTransitions(
                previous: previousStates,
                updated: tripStatusViewModel.participantStates,
                displayNames: displayNames,
                currentUserID: userID
            )
        }

        let content = WidgetContentStateAggregator.aggregate(
            participantStates: states,
            displayNames: displayNames,
            currentUserID: userID
        )
        await liveActivityManager.update(content)
    }

    // MARK: - Trip Lifecycle

    /// Any participant's device — not just whoever tapped "Start Trip" — has
    /// to publish its own location once the trip is active, or that
    /// participant never has data for ETA-1 to compute an ETA/distance from.
    /// The "Start Trip" button only transitions `trip.status`; every device
    /// that subsequently observes the trip is active calls this itself.
    /// Idempotent per trip via `sharingTripID`.
    func ensureLocationSharing(for trip: Trip) async {
        guard trip.status == .active, let tripID = trip.id, sharingTripID != tripID else { return }

        do {
            let userID = try await currentUserID()

            // Only implies background sharing once the user is actually on
            // an active trip — never requested upfront.
            locationService.requestWhenInUseAuthorization()
            locationService.requestAlwaysAuthorization()

            // TRIP-4: notification permission requested here, separately from
            // the location prompts above — its own iOS permission with its
            // own rationale (arrival/delay/nearby alerts), not bundled into
            // LOC-2's location-permission flow.
            notificationPermissionManager.requestPermissions()

            locationSharingCoordinator.startSharing(tripID: tripID, userID: userID)
            try? await locationSyncService.subscribeToLocationUpdates(for: tripID)

            sharingTripID = tripID
            
            // Starts the Live Activity on the device for whoever enters the active trip state
            startLiveActivity(for: trip)
        } catch {
            // Best-effort — this device's ETA/location just won't populate.
        }
    }

    /// Transitions a trip to `.active`. Location sharing for this device is
    /// started via `ensureLocationSharing`, the same path every other
    /// participant's device uses once it observes the trip is active.
    func startTrip(_ trip: Trip) async {
        tripActionErrorMessage = nil
        isUpdatingTripStatus = true
        defer { isUpdatingTripStatus = false }

        do {
            var updatedTrip = trip
            updatedTrip.status = .active
            updatedTrip.updatedAt = Date()
            _ = try await tripService.updateTrip(updatedTrip)

            await ensureLocationSharing(for: updatedTrip)

            await TripStore.shared.loadTrips()
        } catch {
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// `Activity.request` failure (Live Activities disabled in Settings, or
    /// the app is at ActivityKit's concurrent-activity limit) is a soft
    /// failure — trip start must succeed regardless of whether the Live
    /// Activity does.
    private func startLiveActivity(for trip: Trip) {
        guard let tripID = trip.id else { return }

        let totalMates = max(1, participants.filter { $0.tripID == tripID }.count)
        let attributes = OmaweWidgetAttributes(
            tripName: trip.title,
            destinationName: trip.destination,
            totalMates: totalMates
        )
        let initialContent = OmaweWidgetAttributes.ContentState(
            statusMessage: "Waiting for location updates",
            myEtaMinutes: 0,
            myDistanceKm: 0,
            arrivedCount: 0,
            mates: []
        )

        liveActivityManager.start(attributes: attributes, initialContent: initialContent)
    }

    /// Orchestrates TRIP-3's "End Trip" flow, in order: stop location sharing
    /// → end the Live Activity → mark the trip `.ended` — matching the
    /// ticket's required sequence, since deleting the zone first (or out of
    /// order) could leave an in-flight location save or Live Activity update
    /// racing a now-nonexistent zone (`CKError.zoneNotFound`). Zone deletion
    /// itself runs afterward, delayed and best-effort — see
    /// `scheduleZoneCleanup`.
    ///
    /// Owner-only is enforced only client-side (`isOwner` check below) —
    /// `CKShare.publicPermission = .readWrite` (`CloudKitSharingService`)
    /// already grants every participant write access at the CloudKit layer,
    /// so a malicious/buggy client could call this regardless. No
    /// server-side-equivalent enforcement exists; this is a known limitation
    /// of AD-2, tracked rather than silently assumed sufficient (TRIP-3 AC4).
    func endTrip(_ trip: Trip) async {
        tripActionErrorMessage = nil
        isUpdatingTripStatus = true
        defer { isUpdatingTripStatus = false }

        do {
            let userID = try await currentUserID()
            guard isOwner(of: trip, userID: userID) else {
                tripActionErrorMessage = "Only the trip owner can end this trip."
                return
            }

            locationSharingCoordinator.stopSharing()
            sharingTripID = nil

            var updatedTrip = trip
            updatedTrip.status = .ended
            updatedTrip.updatedAt = Date()
            _ = try await tripService.updateTrip(updatedTrip)

            let arrivedCount = tripStatusViewModel.participantStates.values.count { $0.status == .arrived }
            await liveActivityManager.end(OmaweWidgetAttributes.ContentState(
                statusMessage: "Trip ended",
                myEtaMinutes: 0,
                myDistanceKm: 0,
                arrivedCount: arrivedCount,
                mates: []
            ))

            await TripStore.shared.loadTrips()
            scheduleZoneCleanup(for: trip)
        } catch {
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// Deletes the trip's CloudKit zone after a grace delay, best-effort in
    /// the background — deliberately not awaited or blocking on the caller.
    /// Two decisions this makes explicit, since the ticket flags both as open
    /// questions rather than resolving them (docs/Sprint_3/task_2.md):
    /// - **Delay, not immediate**: other participants only see this trip end
    ///   via their own next poll of the (still-existing) `Trip` record: their
    ///   access disappears the moment the zone is gone, so deleting it
    ///   immediately risks yanking access out from under someone who hasn't
    ///   even seen "ended" yet. A short grace window lets that poll land first.
    /// - **Best-effort, not retried inline**: a failure here (e.g. network
    ///   drop mid-delete) leaves a zone undeleted, which only costs unused
    ///   CloudKit storage — a smaller cost than blocking the owner's own
    ///   device on a network-dependent cleanup step after they've already
    ///   been shown "trip ended".
    private func scheduleZoneCleanup(for trip: Trip) {
        guard let tripID = trip.id else { return }
        let zoneID = tripID.zoneID

        Task.detached(priority: .background) { [zoneService] in
            try? await Task.sleep(for: .seconds(30))
            do {
                try await zoneService.deleteZone(with: zoneID)
            } catch {
                debugLog("[HomeViewModel] Zone cleanup failed for trip \(tripID.recordName): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Member Management

    /// Owner-only removal of another participant from a trip.
    func removeParticipant(_ participant: Participant) async {
        tripActionErrorMessage = nil

        guard let participantID = participant.id else { return }

        do {
            let userID = try await currentUserID()
            guard let trip = trips.first(where: { $0.id == participant.tripID }),
                  isOwner(of: trip, userID: userID) else {
                tripActionErrorMessage = "Only the trip owner can remove members."
                return
            }

            try await participantService.removeParticipant(id: participantID)
            await TripStore.shared.loadParticipants()
        } catch {
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// Removes the current user's own participant record from a trip. If the
    /// departing participant was the owner, promotes a remaining participant
    /// (TRIP-2) before reloading — explicit "leave" is the only trigger for
    /// this per TRIP-2's ticket; inactivity/offline is deliberately not,
    /// since AD-6's 30s–2min offline threshold makes going briefly offline a
    /// routine occurrence, not a reliable "gone" signal.
    func leaveTrip(_ trip: Trip) async {
        tripActionErrorMessage = nil

        do {
            let userID = try await currentUserID()
            guard let participant = participants.first(where: { $0.tripID == trip.id && $0.userID == userID }),
                  let participantID = participant.id else {
                return
            }

            let wasOwner = participant.role == .owner
            try await participantService.removeParticipant(id: participantID)

            if wasOwner {
                await reassignOwnershipIfNeeded(tripID: trip.id, departedUserID: userID)
            }

            if sharingTripID == trip.id {
                locationSharingCoordinator.stopSharing()
                sharingTripID = nil
            }

            let arrivedCount = tripStatusViewModel.participantStates.values.count { $0.status == .arrived }
            await liveActivityManager.end(OmaweWidgetAttributes.ContentState(
                statusMessage: "Left trip",
                myEtaMinutes: 0,
                myDistanceKm: 0,
                arrivedCount: arrivedCount,
                mates: []
            ))

            await TripStore.shared.loadTrips()
        } catch {
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// TRIP-2's owner-departure reassignment: re-fetches the participant list
    /// fresh from CloudKit (not the possibly-stale in-memory `participants`)
    /// so the selection policy sees the true remaining set, then promotes the
    /// earliest-joined participant via the conflict-safe `updateParticipant`.
    /// If a racing device's transfer already landed — either the fresh fetch
    /// already shows a new owner, or the conflict-safe save loses the race —
    /// this is a no-op, not an error: exactly one transfer should win.
    private func reassignOwnershipIfNeeded(tripID: CKRecord.ID?, departedUserID: CKRecord.ID) async {
        guard let tripID else { return }

        do {
            let remaining = try await participantService.fetchParticipants(for: tripID)
                .filter { $0.userID != departedUserID }

            guard var newOwner = OwnershipTransferPolicy.selectNewOwner(remaining: remaining) else {
                // Either no one is left (TRIP-3's "last participant leaves"
                // boundary, not this ticket's concern) or someone already
                // holds `.owner` (a racing device's transfer already landed).
                return
            }

            newOwner.role = .owner
            _ = try await participantService.updateParticipant(newOwner)
            await TripStore.shared.loadParticipants()
        } catch CloudKitError.conflict {
            // Another device's transfer won the race for this trip — fine,
            // exactly one promotion is supposed to succeed.
        } catch {
            // Best-effort: worst case, the trip is briefly ownerless until
            // the next leave/refresh retries this.
        }
    }

    func debugFetchAllParticipants(for tripID: CKRecord.ID) async {
        debugLog("🔬 DEBUG: Checking participants for trip:", tripID.recordName)
        debugLog("🔬 Trip zone:", tripID.zoneID.zoneName, "| owner:", tripID.zoneID.ownerName)

        let predicate = NSPredicate(format: "tripID == %@", tripID.recordName)
        let query = CKQuery(recordType: ParticipantRecordMapper.recordType, predicate: predicate)

        // Try private database
        do {
            debugLog("🔬 --- Checking PRIVATE database ---")
            let result = try await privateDatabase.records(matching: query, inZoneWith: tripID.zoneID)
            for (_, matchResult) in result.matchResults {
                switch matchResult {
                case .success(let record):
                    debugLog("✅ [private] Participant record:", record.recordID.recordName)
                    debugLog("   tripID field:", record["tripID"] ?? "nil")
                    debugLog("   userID field:", record["userID"] ?? "nil")
                    debugLog("   role field:", record["role"] ?? "nil")
                    debugLog("   zone:", record.recordID.zoneID.zoneName, "owner:", record.recordID.zoneID.ownerName)
                case .failure(let error):
                    debugLog("❌ [private] match failure:", error)
                }
            }
        } catch {
            debugLog("❌ [private] query failed:", error)
        }

        // Try shared database
        do {
            debugLog("🔬 --- Checking SHARED database ---")
            let result = try await sharedDatabase.records(matching: query, inZoneWith: tripID.zoneID)
            for (_, matchResult) in result.matchResults {
                switch matchResult {
                case .success(let record):
                    debugLog("✅ [shared] Participant record:", record.recordID.recordName)
                    debugLog("   tripID field:", record["tripID"] ?? "nil")
                    debugLog("   userID field:", record["userID"] ?? "nil")
                    debugLog("   role field:", record["role"] ?? "nil")
                    debugLog("   zone:", record.recordID.zoneID.zoneName, "owner:", record.recordID.zoneID.ownerName)
                case .failure(let error):
                    debugLog("❌ [shared] match failure:", error)
                }
            }
        } catch {
            debugLog("❌ [shared] query failed:", error)
        }

        // Also list all zones visible in shared database, to compare zoneID.ownerName
        do {
            debugLog("🔬 --- All zones in SHARED database ---")
            let zones = try await sharedDatabase.allRecordZones()
            for zone in zones {
                debugLog("   zone:", zone.zoneID.zoneName, "| owner:", zone.zoneID.ownerName)
            }
        } catch {
            debugLog("❌ Failed to list shared zones:", error)
        }
    }
    
}
