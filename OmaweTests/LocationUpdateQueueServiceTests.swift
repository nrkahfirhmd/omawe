//
//  LocationUpdateQueueServiceTests.swift
//  OmaweTests
//

import XCTest
import SwiftData
import CloudKit
@testable import Omawe

private actor FakeLocationSyncService: LocationSyncServiceProtocol {
    private(set) var savedSamples: [LocationSample] = []
    var failNextSaves = 0

    func saveLocation(_ location: LocationSample) async throws {
        if failNextSaves > 0 {
            failNextSaves -= 1
            throw CloudKitError.networkUnavailable
        }
        savedSamples.append(location)
    }

    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: Location] {
        [:]
    }

    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws {}
}

final class LocationUpdateQueueServiceTests: XCTestCase {

    private let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
    private lazy var tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
    private let userID = CKRecord.ID(recordName: "user-1")

    private func sample(secondsFromEpoch: TimeInterval) -> LocationSample {
        LocationSample(
            id: nil,
            tripID: tripID,
            userID: userID,
            latitude: 1,
            longitude: 2,
            horizontalAccuracy: nil,
            recordedAt: Date(timeIntervalSince1970: secondsFromEpoch)
        )
    }

    private func makeContext(at url: URL) throws -> ModelContext {
        let configuration = ModelConfiguration(
            schema: Schema([LocationUpdate.self]),
            url: url,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: LocationUpdate.self, configurations: configuration)
        return ModelContext(container)
    }

    func testEnqueue_survivesSimulatedRelaunch() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        do {
            let context = try makeContext(at: storeURL)
            let queue = LocationUpdateQueueService(modelContext: context)
            try queue.enqueue(sample(secondsFromEpoch: 1_700_000_000))
        }

        // Fresh container/context against the same store URL simulates the
        // app being relaunched.
        let relaunchedContext = try makeContext(at: storeURL)
        let stored = try relaunchedContext.fetch(FetchDescriptor<LocationUpdate>())

        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.tripID, tripID)
        XCTAssertFalse(stored.first?.isSynced ?? true)
    }

    func testFlush_sendsInAscendingRecordedAtOrder() async throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let context = try makeContext(at: storeURL)
        let queue = LocationUpdateQueueService(modelContext: context)

        try queue.enqueue(sample(secondsFromEpoch: 300))
        try queue.enqueue(sample(secondsFromEpoch: 100))
        try queue.enqueue(sample(secondsFromEpoch: 200))

        let syncService = FakeLocationSyncService()
        try await queue.flush(using: syncService)

        let saved = await syncService.savedSamples
        XCTAssertEqual(saved.map(\.recordedAt.timeIntervalSince1970), [100, 200, 300])
    }

    func testFlush_doesNotDoubleSendAlreadySyncedEntries() async throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let context = try makeContext(at: storeURL)
        let queue = LocationUpdateQueueService(modelContext: context)
        try queue.enqueue(sample(secondsFromEpoch: 1_700_000_000))

        let syncService = FakeLocationSyncService()
        try await queue.flush(using: syncService)
        try await queue.flush(using: syncService)

        let saved = await syncService.savedSamples
        XCTAssertEqual(saved.count, 1)
    }

    func testFlush_leavesFailedEntryUnsyncedForNextAttempt() async throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let context = try makeContext(at: storeURL)
        let queue = LocationUpdateQueueService(modelContext: context)
        try queue.enqueue(sample(secondsFromEpoch: 1_700_000_000))

        let syncService = FakeLocationSyncService()
        await syncService.setFailNextSaves(1)

        do {
            try await queue.flush(using: syncService)
            XCTFail("Expected flush to throw when the sync service fails")
        } catch {
            // expected
        }

        let stored = try context.fetch(FetchDescriptor<LocationUpdate>())
        XCTAssertFalse(stored.first?.isSynced ?? true)
    }
}

private extension FakeLocationSyncService {
    func setFailNextSaves(_ count: Int) {
        failNextSaves = count
    }
}
