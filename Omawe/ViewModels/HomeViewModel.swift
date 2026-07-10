import SwiftUI
import SwiftData
import CloudKit

@MainActor
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
        
        let nameString = "com.exboyfriends.omawe.reportLate" as CFString
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), ptr, { center, observer, name, object, userInfo in
            guard let observer = observer else { return }
            let viewModel = Unmanaged<HomeViewModel>.fromOpaque(observer).takeUnretainedValue()
            // Jump to main actor
            Task { @MainActor in
                viewModel.reportLate()
            }
        }, nameString, nil, .deliverImmediately)
        
        NotificationCenter.default.addObserver(forName: LocationUpdateNotificationBridge.notificationName, object: nil, queue: .main) { [weak self] notification in
            guard let self = self,
                  let zoneID = notification.object as? CKRecordZone.ID,
                  let activeTrip = self.trips.first(where: { $0.status == .active }),
                  activeTrip.id?.zoneID == zoneID else { return }
            
            Task {
                await self.refreshTripStatus(for: activeTrip, isBackgrounded: UIApplication.shared.applicationState == .background)
            }
        }
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
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

    /// NFR-2: instruments PRD §9's "creation success rate"/"setup time" —
    /// measured from the confirm tap to every dependent CloudKit write succeeding.
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
            let ownerID = try await identityService.currentUserRecordID()

            let invitationCode = inviteService.generateInvitationCode()
            createTripDraft.invitationCode = invitationCode

            let descriptor = FetchDescriptor<UserProfile>()
            let localProfile = try? modelContext.fetch(descriptor).first(where: { $0.userID == UserSession.shared.userIdentifier })
            let ownerName = localProfile?.displayName.isEmpty == false ? localProfile?.displayName : UserSession.shared.displayName

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

            await TripStore.shared.loadTrips()

            hasCreatedTrip = true

            analytics.log(.tripCreateSucceeded(setupSeconds: Date().timeIntervalSince(startedAt)))
            return invitationCode
        } catch {
            print("❌ confirmTripCreation failed with error: \(error)")
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

        // Remove from the left-trip blocklist in case the user is rejoining
        TripStore.shared.unmarkTripAsLeft(tripID)
        await TripStore.shared.loadTrips()
    }

    /// NFR-2: instruments PRD §9's "join success rate"/"setup time" — measured
    /// from share-acceptance start to `CloudKitSharingService.acceptShare` succeeding.
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

    /// Checks `Participant.role` only, not `trip.ownerID` — ownerID is a fixed
    /// CloudKit zone-owner fact (AD-2) that can't follow `reassignOwnershipIfNeeded`,
    /// so it would keep the original owner permanently "owner" even after leaving.
    func isOwner(of trip: Trip, userID: CKRecord.ID) -> Bool {
        participants.contains {
            $0.tripID == trip.id && $0.userID == userID && $0.role == .owner
        }
    }

    // MARK: - ETA / Live Activity (Sprint 2)

    /// nil until `refreshTripStatus` has run at least once for the current user.
    func currentUserTripState(for trip: Trip, userID: CKRecord.ID) -> ParticipantTripState? {
        tripStatusViewModel.participantStates[userID]
    }

    /// Feeds in-app route markers so they match the Live Activity's mate markers.
    var allParticipantTripStates: [CKRecord.ID: ParticipantTripState] {
        tripStatusViewModel.participantStates
    }

    /// Recomputes every participant's ETA/status and pushes it to the Live
    /// Activity. Call on each LOC-1 sync tick, not from a fixed timer.
    func refreshTripStatus(for trip: Trip, isBackgrounded: Bool = false) async {
        guard trip.status == .active,
              let tripID = trip.id,
              let destination = trip.destinationCoordinate else { return }

        await ensureLocationSharing(for: trip)
        
        // Fetch new participants on each polling tick so newly joined members appear
        await TripStore.shared.loadParticipants()

        let previousStates = tripStatusViewModel.participantStates
        await tripStatusViewModel.refresh(tripID: tripID, destination: destination, isBackgrounded: isBackgrounded)
        etaAccuracySampler.recordTransitions(previous: previousStates, updated: tripStatusViewModel.participantStates)

        let states = Array(tripStatusViewModel.participantStates.values)
        let displayNames = Dictionary(
            uniqueKeysWithValues: participants
                .filter { $0.tripID == tripID }
                .compactMap { participant -> (CKRecord.ID, String)? in
                    let displayName = participant.displayName ?? "Unknown"
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
            trackScaleKm: tripStatusViewModel.maxDistanceEverSeen,
            currentUserID: userID
        )
        await liveActivityManager.update(content)
    }

    // MARK: - Trip Lifecycle

    /// Every device on an active trip publishes its own location — "Start
    /// Trip" only flips `trip.status`; each device calls this once it
    /// observes that. Idempotent per trip via `sharingTripID`.
    func ensureLocationSharing(for trip: Trip) async {
        guard trip.status == .active, let tripID = trip.id, sharingTripID != tripID else { return }

        do {
            let userID = try await currentUserID()

            // Location permission is only requested once the user is on an
            // active trip, never upfront.
            locationService.requestWhenInUseAuthorization()
            locationService.requestAlwaysAuthorization()

            // TRIP-4: separate iOS permission from the location prompts above —
            // its own rationale (arrival/delay/nearby alerts).
            notificationPermissionManager.requestPermissions()

            locationSharingCoordinator.startSharing(tripID: tripID, userID: userID)
            try? await locationSyncService.subscribeToLocationUpdates(for: tripID)

            sharingTripID = tripID
            startLiveActivity(for: trip)
        } catch {
            // Best-effort — this device's ETA/location just won't populate.
        }
    }

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

    /// `Activity.request` failure (Live Activities disabled, or at
    /// ActivityKit's concurrency limit) is soft — trip start must succeed regardless.
    private func startLiveActivity(for trip: Trip) {
        guard let tripID = trip.id else { return }

        let tripParticipants = participants.filter { $0.tripID == tripID }
        let totalMates = max(1, tripParticipants.count)
        
        let mates = tripParticipants.compactMap { participant -> OmaweWidgetAttributes.MateProgress? in
            let name = participant.displayName ?? "Unknown"
            let initial = String(name.prefix(1)).uppercased()
            let isMe = participant.userID == cachedUserID
            return OmaweWidgetAttributes.MateProgress(
                label: initial,
                distanceKm: 999.0, // Large enough to not trigger "arrived" green state
                progress: 0.0,
                isMe: isMe
            )
        }

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
            mates: mates
        )

        liveActivityManager.start(attributes: attributes, initialContent: initialContent)
    }

    func reportLate() {
        locationSharingCoordinator.reportLate()
        
        Task { @MainActor in
            let userID = try? await currentUserID()
            
            if let userID {
                tripStatusViewModel.markParticipantLate(userID: userID)
            }
            
            if let activeTrip = trips.first(where: { $0.status == .active }) {
                // Update live activity right now using the optimistic local state
                let states = Array(tripStatusViewModel.participantStates.values)
                let displayNames = Dictionary(
                    uniqueKeysWithValues: participants
                        .filter { $0.tripID == activeTrip.id }
                        .compactMap { participant -> (CKRecord.ID, String)? in
                            let displayName = participant.displayName ?? "Unknown"
                            return (participant.userID, displayName)
                        }
                )
                
                let content = WidgetContentStateAggregator.aggregate(
                    participantStates: states,
                    displayNames: displayNames,
                    trackScaleKm: tripStatusViewModel.maxDistanceEverSeen,
                    currentUserID: userID
                )
                
                await liveActivityManager.update(content)
                
                // Still do the cloud fetch later to ensure backend sync
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await refreshTripStatus(for: activeTrip)
            }
        }
    }

    /// TRIP-3 order matters: stop sharing → end Live Activity → mark `.ended`,
    /// before zone deletion (`scheduleZoneCleanup`) so nothing races a
    /// now-nonexistent zone (`CKError.zoneNotFound`).
    ///
    /// Owner-only is enforced client-side only — `CKShare.publicPermission =
    /// .readWrite` grants every participant CloudKit write access regardless,
    /// a known AD-2 limitation (TRIP-3 AC4).
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
        } catch {
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// Deletes the trip's zone after a grace delay, best-effort and
    /// unawaited: immediate deletion could yank access from a participant
    /// who hasn't polled "ended" yet, and a failed delete only costs unused
    /// CloudKit storage — cheaper than blocking the owner on cleanup.
    private func scheduleZoneCleanup(for trip: Trip) {
        guard let tripID = trip.id else { return }
        let zoneID = tripID.zoneID

        Task.detached(priority: .background) { [zoneService] in
            try? await Task.sleep(for: .seconds(30))
            do {
                try await zoneService.deleteZone(with: zoneID)
            } catch {
                await MainActor.run {
                    debugLog("[HomeViewModel] Zone cleanup failed for trip \(tripID.recordName): \(error.localizedDescription)")
                }
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

    /// If the departing participant was the owner, promotes a remaining one
    /// (TRIP-2). Only explicit "leave" triggers this — inactivity/offline
    /// deliberately doesn't, since AD-6's offline threshold makes brief
    /// disconnects routine, not a reliable "gone" signal.
    func leaveTrip(_ trip: Trip) async {
        tripActionErrorMessage = nil
        print("🚪 User is leaving trip '\(trip.title)' (ID: \(trip.id?.recordName ?? "nil"))...")

        do {
            let userID = try await currentUserID()
            print("👤 Current User ID: \(userID.recordName)")
            
            // Print all participants for debugging
            print("👥 All cached participants count: \(participants.count)")
            for part in participants {
                print("  - Part: tripID=\(part.tripID.recordName), userID=\(part.userID.recordName), role=\(part.role)")
            }
            
            guard let participant = participants.first(where: { $0.tripID == trip.id && $0.userID == userID }) else {
                print("⚠️ Mismatch: Could not find participant record matching current userID \(userID.recordName) for trip \(trip.id?.recordName ?? "nil")!")
                return
            }
            
            guard let participantID = participant.id else {
                print("❌ Mismatch: Participant record has nil ID!")
                return
            }

            let wasOwner = participant.role == .owner
            try await participantService.removeParticipant(id: participantID)

            // Optimistic local removal + blocklist so the UI updates before the re-fetch.
            if let tripID = trip.id {
                TripStore.shared.markTripAsLeft(tripID)
                TripStore.shared.trips.removeAll { $0.id == tripID }
                TripStore.shared.participants.removeAll { $0.tripID == tripID }
            }

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

            // Background refresh to sync with server state
            Task {
                await TripStore.shared.loadTrips()
                await TripStore.shared.loadParticipants()
            }
        } catch {
            print("❌ leaveTrip error: \(error)")
            tripActionErrorMessage = ErrorHelper.simplify(error)
        }
    }

    /// TRIP-2: re-fetches participants fresh from CloudKit (not the possibly
    /// stale in-memory list) and promotes via the conflict-safe
    /// `updateParticipant` — a racing device's transfer landing first makes
    /// this a no-op, not an error.
    private func reassignOwnershipIfNeeded(tripID: CKRecord.ID?, departedUserID: CKRecord.ID) async {
        guard let tripID else { return }

        do {
            let remaining = try await participantService.fetchParticipants(for: tripID)
                .filter { $0.userID != departedUserID }

            // No one left (TRIP-3's separate concern) or a racing transfer already landed.
            guard var newOwner = OwnershipTransferPolicy.selectNewOwner(remaining: remaining) else {
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
