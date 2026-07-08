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
    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let locationService = LocationService()
    private let locationSyncService = CloudKitLocationSyncService()
    private let locationSharingCoordinator: LocationSharingCoordinator
    private let tripStatusViewModel: TripStatusViewModel
    private let liveActivityManager = LiveActivityLifecycleManager()
    private var cachedUserID: CKRecord.ID?

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

        do {
            // MARK: - Current User
            let ownerID = try await identityService.currentUserRecordID()

            // MARK: - Invitation Code
            let invitationCode = inviteService.generateInvitationCode()
            createTripDraft.invitationCode = invitationCode

            // MARK: - Create Trip
            let trip = Trip(
                id: nil,
                title: createTripDraft.name,
                destination: createTripDraft.locationName,
                startDate: createTripDraft.arrivalDate,
                endDate: createTripDraft.arrivalDate,
                ownerID: ownerID,
                invitationCode: invitationCode,
                destinationLatitude: createTripDraft.coordinate?.latitude,
                destinationLongitude: createTripDraft.coordinate?.longitude,
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
                displayName: nil,
                role: .owner,
                joinedAt: Date()
            )

            _ = try await participantService.createParticipant(ownerParticipant)

            let (_, shareURL) = try await sharingService.createShare(for: tripID!)

            try await inviteService.publishInvite(
                code: invitationCode,
                shareURL: shareURL
            )

            // MARK: - Refresh Home Data
            await TripStore.shared.loadTrips()

            hasCreatedTrip = true

            return invitationCode
        } catch {
            creationErrorMessage = error.localizedDescription
            throw error
        }
    }

    func acceptShare(from notification: Notification) async {
        guard let metadata = CloudKitShareAcceptanceBridge.metadata(from: notification) else {
            return
        }

        await acceptShare(metadata)
    }

    func acceptShare(from url: URL) async {
        do {
            try await joinSharedTrip(from: url)
        } catch {
            print("[CloudKitSharing] Share URL acceptance failed: \(error.localizedDescription)")
        }
    }

    func acceptShare(_ metadata: CKShare.Metadata) async {
        do {
            try await joinSharedTrip(metadata)
        } catch {
            print("[CloudKitSharing] Share metadata acceptance failed: \(error.localizedDescription)")
        }
    }

    // TODO: Replace invitation lookup with CloudKitInviteService and native sharing flow.
    func joinTrip(invitationCode: String) async throws {
        shareAcceptanceErrorMessage = nil

        let normalizedCode = invitationCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        print("🔍 Looking up invite:", normalizedCode)

        guard let invite = try await inviteService.findInvite(by: normalizedCode) else {
            print("❌ Invite not found")
            throw CloudKitError.invalidInvitation
        }

        print("✅ Invite found")
        print("Share URL:", invite.shareURL.absoluteString)

        do {
            let tripID = try await joinSharedTrip(from: invite.shareURL)   // ← call own method, not sharingService.joinSharedTrip
            print("✅ Share accepted")

            let currentUserID = try await identityService.currentUserRecordID()
            let participant = Participant(
                id: CKRecord.ID(recordName: UUID().uuidString, zoneID: tripID.zoneID),
                tripID: tripID,
                userID: currentUserID,
                displayName: nil,
                role: .member,
                joinedAt: Date()
            )

            _ = try await participantService.createParticipant(participant)
            print("✅ Participant record created for joiner")

            await TripStore.shared.loadTrips()

        } catch {
            print("❌ Share acceptance failed:", error)
            throw error
        }
    }

    func joinSharedTrip(from url: URL) async throws -> CKRecord.ID {
        shareAcceptanceErrorMessage = nil

        do {
            return try await sharingService.acceptShare(from: url)
        } catch {
            shareAcceptanceErrorMessage = error.localizedDescription
            throw error
        }
    }

    func joinSharedTrip(_ metadata: CKShare.Metadata) async throws -> CKRecord.ID {
        shareAcceptanceErrorMessage = nil

        do {
            return try await sharingService.acceptShare(metadata)
        } catch {
            shareAcceptanceErrorMessage = error.localizedDescription
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

    func isOwner(of trip: Trip, userID: CKRecord.ID) -> Bool {
        if trip.ownerID == userID { return true }
        return participants.contains {
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

        await tripStatusViewModel.refresh(tripID: tripID, destination: destination, isBackgrounded: isBackgrounded)

        let states = Array(tripStatusViewModel.participantStates.values)
        let displayNames = Dictionary(
            uniqueKeysWithValues: participants
                .filter { $0.tripID == tripID }
                .compactMap { participant -> (CKRecord.ID, String)? in
                    guard let displayName = participant.displayName else { return nil }
                    return (participant.userID, displayName)
                }
        )

        let content = WidgetContentStateAggregator.aggregate(participantStates: states, displayNames: displayNames)
        await liveActivityManager.update(content)
    }

    // MARK: - Trip Lifecycle

    /// Transitions a trip to `.active` and starts publishing this device's
    /// location into LOC-1's sync path for the rest of the trip's participants.
    func startTrip(_ trip: Trip) async {
        guard let tripID = trip.id else { return }
        tripActionErrorMessage = nil
        isUpdatingTripStatus = true
        defer { isUpdatingTripStatus = false }

        do {
            let userID = try await currentUserID()

            var updatedTrip = trip
            updatedTrip.status = .active
            updatedTrip.updatedAt = Date()
            _ = try await tripService.updateTrip(updatedTrip)

            // Only implies background sharing once the user has actually
            // started a trip — never requested upfront.
            locationService.requestWhenInUseAuthorization()
            locationService.requestAlwaysAuthorization()
            locationSharingCoordinator.startSharing(tripID: tripID, userID: userID)
            try? await locationSyncService.subscribeToLocationUpdates(for: tripID)

            startLiveActivity(for: updatedTrip)

            await TripStore.shared.loadTrips()
        } catch {
            tripActionErrorMessage = error.localizedDescription
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
            etaMinutes: 0,
            arrivedCount: 0,
            distanceKm: 0
        )

        liveActivityManager.start(attributes: attributes, initialContent: initialContent)
    }

    /// Orchestrates TRIP-3's "End Trip" flow: stop location sharing, then mark
    /// the trip ended. Zone cleanup is deliberately not performed here — it
    /// would destroy shared data for every other participant immediately with
    /// no warning (see docs/Sprint_3/task_2.md), so it's left out of scope.
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

            var updatedTrip = trip
            updatedTrip.status = .ended
            updatedTrip.updatedAt = Date()
            _ = try await tripService.updateTrip(updatedTrip)

            let arrivedCount = tripStatusViewModel.participantStates.values.count { $0.status == .arrived }
            await liveActivityManager.end(OmaweWidgetAttributes.ContentState(
                statusMessage: "Trip ended",
                etaMinutes: 0,
                arrivedCount: arrivedCount,
                distanceKm: 0
            ))

            await TripStore.shared.loadTrips()
        } catch {
            tripActionErrorMessage = error.localizedDescription
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
            tripActionErrorMessage = error.localizedDescription
        }
    }

    /// Removes the current user's own participant record from a trip.
    func leaveTrip(_ trip: Trip) async {
        tripActionErrorMessage = nil

        do {
            let userID = try await currentUserID()
            guard let participant = participants.first(where: { $0.tripID == trip.id && $0.userID == userID }),
                  let participantID = participant.id else {
                return
            }

            try await participantService.removeParticipant(id: participantID)
            await TripStore.shared.loadTrips()
        } catch {
            tripActionErrorMessage = error.localizedDescription
        }
    }

    func debugFetchAllParticipants(for tripID: CKRecord.ID) async {
        print("🔬 DEBUG: Checking participants for trip:", tripID.recordName)
        print("🔬 Trip zone:", tripID.zoneID.zoneName, "| owner:", tripID.zoneID.ownerName)

        let predicate = NSPredicate(format: "tripID == %@", tripID.recordName)
        let query = CKQuery(recordType: ParticipantRecordMapper.recordType, predicate: predicate)

        // Try private database
        do {
            print("🔬 --- Checking PRIVATE database ---")
            let result = try await privateDatabase.records(matching: query, inZoneWith: tripID.zoneID)
            for (_, matchResult) in result.matchResults {
                switch matchResult {
                case .success(let record):
                    print("✅ [private] Participant record:", record.recordID.recordName)
                    print("   tripID field:", record["tripID"] ?? "nil")
                    print("   userID field:", record["userID"] ?? "nil")
                    print("   role field:", record["role"] ?? "nil")
                    print("   zone:", record.recordID.zoneID.zoneName, "owner:", record.recordID.zoneID.ownerName)
                case .failure(let error):
                    print("❌ [private] match failure:", error)
                }
            }
        } catch {
            print("❌ [private] query failed:", error)
        }

        // Try shared database
        do {
            print("🔬 --- Checking SHARED database ---")
            let result = try await sharedDatabase.records(matching: query, inZoneWith: tripID.zoneID)
            for (_, matchResult) in result.matchResults {
                switch matchResult {
                case .success(let record):
                    print("✅ [shared] Participant record:", record.recordID.recordName)
                    print("   tripID field:", record["tripID"] ?? "nil")
                    print("   userID field:", record["userID"] ?? "nil")
                    print("   role field:", record["role"] ?? "nil")
                    print("   zone:", record.recordID.zoneID.zoneName, "owner:", record.recordID.zoneID.ownerName)
                case .failure(let error):
                    print("❌ [shared] match failure:", error)
                }
            }
        } catch {
            print("❌ [shared] query failed:", error)
        }

        // Also list all zones visible in shared database, to compare zoneID.ownerName
        do {
            print("🔬 --- All zones in SHARED database ---")
            let zones = try await sharedDatabase.allRecordZones()
            for zone in zones {
                print("   zone:", zone.zoneID.zoneName, "| owner:", zone.zoneID.ownerName)
            }
        } catch {
            print("❌ Failed to list shared zones:", error)
        }
    }
    
}
