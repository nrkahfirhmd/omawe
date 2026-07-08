//
//  LiveActivityLifecycleManagerTests.swift
//  OmaweTests
//

import XCTest
@testable import Omawe

private enum FakeActivityError: Error {
    case liveActivitiesDisabled
}

private final class FakeLiveActivityController: LiveActivityControlling {
    var shouldFailStart = false
    private(set) var startCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var endCallCount = 0
    private(set) var lastUpdatedContent: OmaweWidgetAttributes.ContentState?

    func start(attributes: OmaweWidgetAttributes, content: OmaweWidgetAttributes.ContentState) throws {
        startCallCount += 1
        if shouldFailStart {
            throw FakeActivityError.liveActivitiesDisabled
        }
    }

    func update(content: OmaweWidgetAttributes.ContentState) async {
        updateCallCount += 1
        lastUpdatedContent = content
    }

    func end(content: OmaweWidgetAttributes.ContentState) async {
        endCallCount += 1
    }
}

final class LiveActivityLifecycleManagerTests: XCTestCase {

    private let attributes = OmaweWidgetAttributes(tripName: "Trip", destinationName: "Destination", totalMates: 3)

    private func content(eta: Int = 10, distance: Double = 5, arrived: Int = 0) -> OmaweWidgetAttributes.ContentState {
        OmaweWidgetAttributes.ContentState(statusMessage: "on the way", myEtaMinutes: eta, myDistanceKm: distance, arrivedCount: arrived, mates: [])
    }

    func testStart_success_becomesActive() {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)

        manager.start(attributes: attributes, initialContent: content())

        XCTAssertEqual(controller.startCallCount, 1)
        XCTAssertTrue(manager.isActive)
        XCTAssertNil(manager.lastErrorMessage)
    }

    func testStart_activityRequestThrows_isSoftFailureNotCrash() {
        let controller = FakeLiveActivityController()
        controller.shouldFailStart = true
        let manager = LiveActivityLifecycleManager(controller: controller)

        manager.start(attributes: attributes, initialContent: content())

        XCTAssertFalse(manager.isActive)
        XCTAssertNotNil(manager.lastErrorMessage)
    }

    func testUpdate_beforeStart_isNoOp() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)

        await manager.update(content())

        XCTAssertEqual(controller.updateCallCount, 0)
    }

    func testUpdate_meaningfulChange_forwardsToController() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)
        manager.start(attributes: attributes, initialContent: content(eta: 10))

        await manager.update(content(eta: 5))

        XCTAssertEqual(controller.updateCallCount, 1)
        XCTAssertEqual(controller.lastUpdatedContent?.myEtaMinutes, 5)
    }

    func testUpdate_identicalContent_isThrottledAwayNotForwarded() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)
        let initial = content(eta: 10)
        manager.start(attributes: attributes, initialContent: initial)

        await manager.update(initial)

        XCTAssertEqual(controller.updateCallCount, 0, "Identical content shouldn't count against ActivityKit's update budget")
    }

    func testEnd_afterStart_endsAndDeactivates() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)
        manager.start(attributes: attributes, initialContent: content())

        await manager.end(content(eta: 0, arrived: 3))

        XCTAssertEqual(controller.endCallCount, 1)
        XCTAssertFalse(manager.isActive)
    }

    func testEnd_beforeStart_isNoOp() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)

        await manager.end(content())

        XCTAssertEqual(controller.endCallCount, 0)
    }

    func testUpdate_afterEnd_isNoOp() async {
        let controller = FakeLiveActivityController()
        let manager = LiveActivityLifecycleManager(controller: controller)
        manager.start(attributes: attributes, initialContent: content(eta: 10))
        await manager.end(content(eta: 0))

        await manager.update(content(eta: 5))

        XCTAssertEqual(controller.updateCallCount, 0)
    }
}
