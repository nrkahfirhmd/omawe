import XCTest
import CoreLocation
import CloudKit
@testable import Omawe

private final class FakeRouteProvider: RouteProviding {
    enum Behavior {
        case succeed(RouteResult)
        case fail
    }

    var behavior: Behavior = .succeed(RouteResult(etaSeconds: 600, distanceMeters: 5_000))
    private(set) var callCount = 0

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteResult {
        callCount += 1
        switch behavior {
        case .succeed(let result):
            return result
        case .fail:
            throw RouteProvidingError.noRouteFound
        }
    }
}

private actor FakeLocationSyncService: LocationSyncServiceProtocol {
    private var locationsToReturn: [CKRecord.ID: LocationSample] = [:]

    func setLocations(_ locations: [CKRecord.ID: LocationSample]) {
        locationsToReturn = locations
    }

    func saveLocation(_ location: LocationSample) async throws {}

    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: LocationSample] {
        locationsToReturn
    }

    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws {}
}

final class TripStatusViewModelTests: XCTestCase {

    private let tripID = CKRecord.ID(recordName: "trip-1")
    private let userID = CKRecord.ID(recordName: "user-1")
    private let destination = CLLocationCoordinate2D(latitude: 1, longitude: 1)
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func sample(latitude: Double, longitude: Double, secondsAgo: TimeInterval = 0) -> LocationSample {
        LocationSample(
            id: nil,
            tripID: tripID,
            userID: userID,
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: nil,
            recordedAt: now.addingTimeInterval(-secondsAgo)
        )
    }

    // MARK: - Fallback selection

    func testRefresh_routeSucceeds_usesRouteResult() async {
        let syncService = FakeLocationSyncService()
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0)])
        let routeProvider = FakeRouteProvider()
        routeProvider.behavior = .succeed(RouteResult(etaSeconds: 600, distanceMeters: 5_000))

        let viewModel = TripStatusViewModel(locationSyncService: syncService, routeProvider: routeProvider, now: { self.now })
        await viewModel.refresh(tripID: tripID, destination: destination)

        let state = viewModel.participantStates[userID]
        XCTAssertEqual(state?.etaMinutes, 10)
        XCTAssertEqual(state?.distanceKm ?? 0, 5.0, accuracy: 0.001)
        XCTAssertEqual(state?.usedFallback, false)
    }

    func testRefresh_routeFails_fallsBackToStraightLineDistanceWithNoETA() async {
        let syncService = FakeLocationSyncService()
        let origin = sample(latitude: 0, longitude: 0)
        await syncService.setLocations([userID: origin])
        let routeProvider = FakeRouteProvider()
        routeProvider.behavior = .fail

        let viewModel = TripStatusViewModel(locationSyncService: syncService, routeProvider: routeProvider, now: { self.now })
        await viewModel.refresh(tripID: tripID, destination: destination)

        let expectedDistanceMeters = LocationCore.straightLineDistance(
            from: Location(latitude: 0, longitude: 0),
            to: Location(coordinate: destination)
        )

        let state = viewModel.participantStates[userID]
        XCTAssertNil(state?.etaMinutes)
        XCTAssertEqual(state?.distanceKm ?? 0, expectedDistanceMeters / 1000, accuracy: 0.001)
        XCTAssertEqual(state?.usedFallback, true)
    }

    // MARK: - Throttle

    func testRefresh_noMovementBetweenTicks_reusesCachedRouteWithoutRerequesting() async {
        let syncService = FakeLocationSyncService()
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0)])
        let routeProvider = FakeRouteProvider()

        let viewModel = TripStatusViewModel(
            locationSyncService: syncService,
            routeProvider: routeProvider,
            movementThresholdMeters: 200,
            now: { self.now }
        )

        await viewModel.refresh(tripID: tripID, destination: destination)
        XCTAssertEqual(routeProvider.callCount, 1)

        // Same coordinate again — no meaningful movement.
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0)])
        await viewModel.refresh(tripID: tripID, destination: destination)

        XCTAssertEqual(routeProvider.callCount, 1, "Sub-threshold movement should reuse the cached route, not re-request MKDirections")
    }

    func testRefresh_movementPastThreshold_requestsNewRoute() async {
        let syncService = FakeLocationSyncService()
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0)])
        let routeProvider = FakeRouteProvider()

        let viewModel = TripStatusViewModel(
            locationSyncService: syncService,
            routeProvider: routeProvider,
            movementThresholdMeters: 200,
            now: { self.now }
        )

        await viewModel.refresh(tripID: tripID, destination: destination)
        XCTAssertEqual(routeProvider.callCount, 1)

        // ~334m north of the original point — past the 200m threshold.
        await syncService.setLocations([userID: sample(latitude: 0.003, longitude: 0)])
        await viewModel.refresh(tripID: tripID, destination: destination)

        XCTAssertEqual(routeProvider.callCount, 2, "Past-threshold movement should trigger a fresh MKDirections request")
    }

    // MARK: - Staleness

    func testRefresh_staleLocation_marksParticipantStale() async {
        let syncService = FakeLocationSyncService()
        // Foregrounded offline threshold is 30s (LocationCore) — 40s ago is stale.
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0, secondsAgo: 40)])
        let routeProvider = FakeRouteProvider()

        let viewModel = TripStatusViewModel(locationSyncService: syncService, routeProvider: routeProvider, now: { self.now })
        await viewModel.refresh(tripID: tripID, destination: destination, isBackgrounded: false)

        XCTAssertEqual(viewModel.participantStates[userID]?.isStale, true)
    }

    func testRefresh_freshLocation_notStale() async {
        let syncService = FakeLocationSyncService()
        await syncService.setLocations([userID: sample(latitude: 0, longitude: 0, secondsAgo: 5)])
        let routeProvider = FakeRouteProvider()

        let viewModel = TripStatusViewModel(locationSyncService: syncService, routeProvider: routeProvider, now: { self.now })
        await viewModel.refresh(tripID: tripID, destination: destination, isBackgrounded: false)

        XCTAssertEqual(viewModel.participantStates[userID]?.isStale, false)
    }
}
