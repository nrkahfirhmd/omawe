import CloudKit

final class LocationSharingCoordinator {
    private let locationService: LocationServiceProtocol
    private let syncService: LocationSyncServiceProtocol
    private let queueService: LocationUpdateQueueServiceProtocol
    private var forwardingTask: Task<Void, Never>?
    private var reportedLateAt: Date?
    private var currentTripID: CKRecord.ID?
    private var currentUserID: CKRecord.ID?
    private var lastLocation: CLLocation?

    init(
        locationService: LocationServiceProtocol,
        syncService: LocationSyncServiceProtocol,
        queueService: LocationUpdateQueueServiceProtocol = LocationUpdateQueueService.shared
    ) {
        self.locationService = locationService
        self.syncService = syncService
        self.queueService = queueService
    }

    func startSharing(tripID: CKRecord.ID, userID: CKRecord.ID) {
        stopSharing()
        
        currentTripID = tripID
        currentUserID = userID

        locationService.startUpdating()

        forwardingTask = Task { [weak self, locationService, syncService, queueService] in
            // best-effort catch-up before this tick's own saves
            try? await queueService.flush(using: syncService)

            for await location in locationService.locationUpdates {
                self?.lastLocation = location
                
                let sample = LocationSample(
                    id: nil,
                    tripID: tripID,
                    userID: userID,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    recordedAt: location.timestamp,
                    reportedLateAt: self?.reportedLateAt
                )

                do {
                    try await syncService.saveLocation(sample)
                } catch {
                    try? queueService.enqueue(sample)
                }
            }
        }
    }

    func stopSharing() {
        forwardingTask?.cancel()
        forwardingTask = nil
        reportedLateAt = nil
        currentTripID = nil
        currentUserID = nil
        lastLocation = nil
        locationService.stopUpdating()
    }
    
    func reportLate() {
        reportedLateAt = Date()
        
        guard let tripID = currentTripID,
              let userID = currentUserID,
              let location = lastLocation else { return }
              
        // Use Date() so this record's recordedAt is guaranteed to be newer than any prior GPS-driven record
        let sample = LocationSample(
            id: nil,
            tripID: tripID,
            userID: userID,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy,
            recordedAt: Date(),
            reportedLateAt: reportedLateAt
        )
        
        Task { [syncService, queueService] in
            do {
                try await syncService.saveLocation(sample)
            } catch {
                try? queueService.enqueue(sample)
            }
        }
    }
}
