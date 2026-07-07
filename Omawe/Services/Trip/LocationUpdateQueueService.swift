//
//  LocationUpdateQueueService.swift
//  Omawe
//

import Foundation
import SwiftData

protocol LocationUpdateQueueServiceProtocol {
    func enqueue(_ sample: LocationSample) throws
    func flush(using syncService: LocationSyncServiceProtocol) async throws
}

/// LOC-4's local-only offline write queue for location updates, backed by
/// `LocationUpdate` (SwiftData, no CloudKit mirroring — see OmaweApp.swift).
/// A captured sample is durably queued here first, then flushed through
/// LOC-1's `CloudKitLocationSyncService`; a queued-but-unsynced item survives
/// the app being killed before flush because it's on-disk, not in-memory.
final class LocationUpdateQueueService: LocationUpdateQueueServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func enqueue(_ sample: LocationSample) throws {
        let update = LocationUpdate(
            tripID: sample.tripID,
            userID: sample.userID,
            latitude: sample.latitude,
            longitude: sample.longitude,
            horizontalAccuracy: sample.horizontalAccuracy,
            recordedAt: sample.recordedAt
        )
        modelContext.insert(update)
        try modelContext.save()
    }

    /// Drains unsynced entries oldest-first. Marks each synced immediately
    /// after its save succeeds, so a second flush (e.g. after a relaunch)
    /// never re-sends it.
    func flush(using syncService: LocationSyncServiceProtocol) async throws {
        var descriptor = FetchDescriptor<LocationUpdate>(
            predicate: #Predicate { !$0.isSynced }
        )
        descriptor.sortBy = [SortDescriptor(\.recordedAt, order: .forward)]

        let pending = try modelContext.fetch(descriptor)

        for update in pending {
            try await syncService.saveLocation(update.asLocationSample)
            update.isSynced = true
            try modelContext.save()
        }
    }
}
