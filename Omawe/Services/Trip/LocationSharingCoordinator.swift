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
    private var forwardingTask: Task<Void, Never>?

    init(
        locationService: LocationServiceProtocol,
        syncService: LocationSyncServiceProtocol
    ) {
        self.locationService = locationService
        self.syncService = syncService
    }

    func startSharing(tripID: CKRecord.ID, userID: CKRecord.ID) {
        stopSharing()

        locationService.startUpdating()

        forwardingTask = Task { [locationService, syncService] in
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

                // Failures here already carry a CloudKitError from LOC-1;
                // surfacing them to the UI is NFR-1's concern, not this seam's.
                _ = try? await syncService.saveLocation(sample)
            }
        }
    }

    func stopSharing() {
        forwardingTask?.cancel()
        forwardingTask = nil
        locationService.stopUpdating()
    }
}
