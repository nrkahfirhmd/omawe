import XCTest
import CoreLocation
import CloudKit
@testable import Omawe

private final class FakeLocationService: LocationServiceProtocol {
    var authorizationState: LocationAuthorizationState = .authorizedWhenInUse
    let locationUpdates: AsyncStream<CLLocation>
    let continuation: AsyncStream<CLLocation>.Continuation

    private(set) var startUpdatingCallCount = 0
    private(set) var stopUpdatingCallCount = 0

    init() {
        var continuation: AsyncStream<CLLocation>.Continuation!
        locationUpdates = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}

    func startUpdating() {
        startUpdatingCallCount += 1
    }

    func stopUpdating() {
        stopUpdatingCallCount += 1
    }
}

private actor FakeLocationSyncService: LocationSyncServiceProtocol {
    private(set) var savedSamples: [LocationSample] = []

    func saveLocation(_ location: LocationSample) async throws {
        savedSamples.append(location)
    }

    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: LocationSample] {
        [:]
    }

    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws {}
}

final class LocationSharingCoordinatorTests: XCTestCase {

    func testStartSharing_forwardsCapturedLocationsAsSamplesForTheGivenTripAndUser() async throws {
        let locationService = FakeLocationService()
        let syncService = FakeLocationSyncService()
        let coordinator = LocationSharingCoordinator(locationService: locationService, syncService: syncService)

        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")

        coordinator.startSharing(tripID: tripID, userID: userID)
        XCTAssertEqual(locationService.startUpdatingCallCount, 1)

        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: -6.2, longitude: 106.8),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        locationService.continuation.yield(location)
        locationService.continuation.finish()

        try await Task.sleep(nanoseconds: 50_000_000)

        let saved = await syncService.savedSamples
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.tripID, tripID)
        XCTAssertEqual(saved.first?.userID, userID)
        XCTAssertEqual(saved.first?.latitude, -6.2)
        XCTAssertEqual(saved.first?.longitude, 106.8)
        XCTAssertEqual(saved.first?.horizontalAccuracy, 10)

        let stopCountBeforeFinalStop = locationService.stopUpdatingCallCount
        coordinator.stopSharing()
        XCTAssertEqual(locationService.stopUpdatingCallCount, stopCountBeforeFinalStop + 1)
    }
}
