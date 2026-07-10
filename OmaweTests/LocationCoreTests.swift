import XCTest
import CoreLocation
@testable import Omawe

final class LocationCoreTests: XCTestCase {

    // MARK: - straightLineDistance

    func testStraightLineDistance_sameCoordinate_isZero() {
        let point = Location(latitude: -6.2, longitude: 106.8)
        XCTAssertEqual(LocationCore.straightLineDistance(from: point, to: point), 0, accuracy: 0.001)
    }

    // MARK: - isNearDestination

    func testIsNearDestination_atExactDistanceThreshold_isTrue() {
        XCTAssertTrue(LocationCore.isNearDestination(distance: 1_000, etaMinutes: nil))
    }

    func testIsNearDestination_justOverDistanceThreshold_withNoETA_isFalse() {
        XCTAssertFalse(LocationCore.isNearDestination(distance: 1_000.1, etaMinutes: nil))
    }

    func testIsNearDestination_atExactETAThreshold_isTrue() {
        XCTAssertTrue(LocationCore.isNearDestination(distance: 5_000, etaMinutes: 3))
    }

    func testIsNearDestination_justOverETAThreshold_isFalse() {
        XCTAssertFalse(LocationCore.isNearDestination(distance: 5_000, etaMinutes: 4))
    }

    func testIsNearDestination_nilETA_farDistance_isFalse() {
        XCTAssertFalse(LocationCore.isNearDestination(distance: 5_000, etaMinutes: nil))
    }

    // MARK: - isDelayed

    func testIsDelayed_atExactThreshold_isTrue() {
        XCTAssertTrue(LocationCore.isDelayed(currentETA: 700, etaAtLastOnTheWay: 100))
    }

    func testIsDelayed_justUnderThreshold_isFalse() {
        XCTAssertFalse(LocationCore.isDelayed(currentETA: 699, etaAtLastOnTheWay: 100))
    }

    // MARK: - isOffline

    func testIsOffline_backgrounded_atExactThreshold_isTrue() {
        let now = Date()
        let lastUpdate = now.addingTimeInterval(-120)
        XCTAssertTrue(LocationCore.isOffline(lastUpdate: lastUpdate, isBackgrounded: true, now: now))
    }

    func testIsOffline_backgrounded_justUnderThreshold_isFalse() {
        let now = Date()
        let lastUpdate = now.addingTimeInterval(-119)
        XCTAssertFalse(LocationCore.isOffline(lastUpdate: lastUpdate, isBackgrounded: true, now: now))
    }

    func testIsOffline_foregrounded_atExactThreshold_isTrue() {
        let now = Date()
        let lastUpdate = now.addingTimeInterval(-30)
        XCTAssertTrue(LocationCore.isOffline(lastUpdate: lastUpdate, isBackgrounded: false, now: now))
    }

    func testIsOffline_foregrounded_justUnderThreshold_isFalse() {
        let now = Date()
        let lastUpdate = now.addingTimeInterval(-29)
        XCTAssertFalse(LocationCore.isOffline(lastUpdate: lastUpdate, isBackgrounded: false, now: now))
    }
}
