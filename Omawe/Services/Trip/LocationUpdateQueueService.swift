import Foundation
import SwiftData

protocol LocationUpdateQueueServiceProtocol {
    func enqueue(_ sample: LocationSample) throws
    func flush(using syncService: LocationSyncServiceProtocol) async throws
}

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
    /// after its save succeeds, so a second flush never re-sends it.
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

extension LocationUpdateQueueService {
    static let shared: LocationUpdateQueueService = {
        let schema = Schema([LocationUpdate.self])
        let configuration = ModelConfiguration(
            "LocationUpdateStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return LocationUpdateQueueService(modelContext: ModelContext(container))
        } catch {
            fatalError("Could not create LocationUpdateQueueService's model container: \(error)")
        }
    }()
}
