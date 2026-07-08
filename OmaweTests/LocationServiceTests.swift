//
//  LocationServiceTests.swift
//  OmaweTests
//

import XCTest
import CoreLocation
@testable import Omawe

final class LocationServiceStateMappingTests: XCTestCase {

    func testNotDetermined() {
        XCTAssertEqual(
            LocationService.state(authorization: .notDetermined, accuracy: .fullAccuracy),
            .notDetermined
        )
    }

    func testDenied() {
        XCTAssertEqual(
            LocationService.state(authorization: .denied, accuracy: .fullAccuracy),
            .denied
        )
    }

    func testRestricted() {
        XCTAssertEqual(
            LocationService.state(authorization: .restricted, accuracy: .fullAccuracy),
            .restricted
        )
    }

    func testAuthorizedWhenInUse_fullAccuracy() {
        XCTAssertEqual(
            LocationService.state(authorization: .authorizedWhenInUse, accuracy: .fullAccuracy),
            .authorizedWhenInUse
        )
    }

    func testAuthorizedWhenInUse_reducedAccuracy() {
        XCTAssertEqual(
            LocationService.state(authorization: .authorizedWhenInUse, accuracy: .reducedAccuracy),
            .authorizedReducedAccuracy
        )
    }

    func testAuthorizedAlways_fullAccuracy() {
        XCTAssertEqual(
            LocationService.state(authorization: .authorizedAlways, accuracy: .fullAccuracy),
            .authorizedAlways
        )
    }

    func testAuthorizedAlways_reducedAccuracy() {
        XCTAssertEqual(
            LocationService.state(authorization: .authorizedAlways, accuracy: .reducedAccuracy),
            .authorizedReducedAccuracy
        )
    }
}

private final class FakeLocationManager: CLLocationManagerRepresentable {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = 0
    var allowsBackgroundLocationUpdates: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy

    var requestWhenInUseAuthorizationCallCount = 0
    var requestAlwaysAuthorizationCallCount = 0
    var startUpdatingLocationCallCount = 0
    var stopUpdatingLocationCallCount = 0

    func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCallCount += 1
    }

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCallCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingLocationCallCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }
}

final class LocationServiceInteractionTests: XCTestCase {

    func testInit_tunesAccuracyAndDistanceFilterForThirtySecondBudget_notMaximumPrecision() {
        let manager = FakeLocationManager()
        _ = LocationService(manager: manager)

        XCTAssertNotEqual(manager.desiredAccuracy, kCLLocationAccuracyBest)
        XCTAssertGreaterThan(manager.distanceFilter, 0)
    }

    func testRequestWhenInUseAuthorization_callsThroughToManager() {
        let manager = FakeLocationManager()
        let service = LocationService(manager: manager)

        service.requestWhenInUseAuthorization()

        XCTAssertEqual(manager.requestWhenInUseAuthorizationCallCount, 1)
        XCTAssertEqual(manager.requestAlwaysAuthorizationCallCount, 0)
    }

    func testRequestAlwaysAuthorization_isNeverCalledImplicitly() {
        let manager = FakeLocationManager()
        _ = LocationService(manager: manager)

        XCTAssertEqual(manager.requestAlwaysAuthorizationCallCount, 0)
    }

    func testRequestAlwaysAuthorization_callsThroughOnlyWhenExplicitlyInvoked() {
        let manager = FakeLocationManager()
        let service = LocationService(manager: manager)

        service.requestAlwaysAuthorization()

        XCTAssertEqual(manager.requestAlwaysAuthorizationCallCount, 1)
    }

    func testStartUpdating_callsThroughToManager() {
        let manager = FakeLocationManager()
        let service = LocationService(manager: manager)

        service.startUpdating()

        XCTAssertEqual(manager.startUpdatingLocationCallCount, 1)
    }

    func testStopUpdating_callsThroughAndDisablesBackgroundUpdates() {
        let manager = FakeLocationManager()
        manager.allowsBackgroundLocationUpdates = true
        let service = LocationService(manager: manager)

        service.stopUpdating()

        XCTAssertEqual(manager.stopUpdatingLocationCallCount, 1)
        XCTAssertFalse(manager.allowsBackgroundLocationUpdates)
    }
}
