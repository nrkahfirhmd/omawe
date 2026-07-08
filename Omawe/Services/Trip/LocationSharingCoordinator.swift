//
//  LocationSharingCoordinator.swift
//  Omawe
//

import CloudKit

/// The seam between "device has a location" (LOC-2's `LocationService`) and
/// "location is synced" (LOC-1's `CloudKitLocationSyncService`). Keeps
/// `LocationService` itself free of CloudKit knowledge (AD-3 service-per-
/// concern layout).
final class LocationSharingCoordinator {
    private let locationService: LocationServiceProtocol
    private let syncService: LocationSyncServiceProtocol
    private let queueService: LocationUpdateQueueServiceProtocol
    private var forwardingTask: Task<Void, Never>?

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

        locationService.startUpdating()

        forwardingTask = Task { [locationService, syncService, queueService] in
            // NFR-3: best-effort catch-up before this tick's own saves — a
            // sample queued by an earlier exhausted-retry failure gets
            // another chance as soon as sharing (re)starts, rather than
            // waiting on a manual retry path that doesn't exist.
            try? await queueService.flush(using: syncService)

            for await location in locationService.locationUpdates {
                let sample = LocationSample(
                    id: nil,
                    tripID: tripID,
                    userID: userID,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    recordedAt: location.timestamp
                )

                // `saveLocation` already retries transient failures
                // internally (NFR-3/`RetryExecutor`) before ever throwing —
                // reaching this catch means retries are exhausted, so queue
                // the sample into LOC-4's durable offline queue instead of
                // silently dropping it. Surfacing this failure to the UI is
                // NFR-1's concern, not this seam's.
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
        locationService.stopUpdating()
    }
}
