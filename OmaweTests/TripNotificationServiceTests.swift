import XCTest
import CloudKit
import UserNotifications
@testable import Omawe

private final class FakeNotificationScheduling: NotificationScheduling {
    private(set) var scheduledRequests: [UNNotificationRequest] = []

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        scheduledRequests.append(request)
        completionHandler?(nil)
    }
}

final class TripNotificationServiceTests: XCTestCase {

    private let currentUserID = CKRecord.ID(recordName: "me")
    private let otherUserID = CKRecord.ID(recordName: "other")
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func state(userID: CKRecord.ID, status: ParticipantTripStatus) -> ParticipantTripState {
        ParticipantTripState(
            userID: userID,
            etaMinutes: 5,
            distanceKm: 1,
            status: status,
            isStale: false,
            usedFallback: false
        )
    }

    func testNotifyTransitions_otherParticipantTransitionsToArrived_schedulesNotification() {
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, now: { self.now })

        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            updated: [otherUserID: state(userID: otherUserID, status: .arrived)],
            displayNames: [otherUserID: "Alex"],
            currentUserID: currentUserID
        )

        XCTAssertEqual(fake.scheduledRequests.count, 1)
        XCTAssertEqual(fake.scheduledRequests.first?.content.title, "Arrived")
        XCTAssertTrue(fake.scheduledRequests.first?.content.body.contains("Alex") ?? false)
    }

    func testNotifyTransitions_currentUsersOwnTransition_doesNotNotify() {
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, now: { self.now })

        service.notifyTransitions(
            previous: [currentUserID: state(userID: currentUserID, status: .onTheWay)],
            updated: [currentUserID: state(userID: currentUserID, status: .arrived)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        XCTAssertTrue(fake.scheduledRequests.isEmpty)
    }

    func testNotifyTransitions_nonNotifiableStatus_doesNotNotify() {
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, now: { self.now })

        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .arrived)],
            updated: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        XCTAssertTrue(fake.scheduledRequests.isEmpty)
    }

    func testNotifyTransitions_noStatusChange_doesNotReNotify() {
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, now: { self.now })

        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .arrived)],
            updated: [otherUserID: state(userID: otherUserID, status: .arrived)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        XCTAssertTrue(fake.scheduledRequests.isEmpty)
    }

    func testNotifyTransitions_flappingAcrossBoundaryWithinCooldown_suppressedBySecondNotification() {
        var clock = now
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, cooldown: 300, now: { clock })

        // onTheWay -> nearDestination: first real transition, notifies.
        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            updated: [otherUserID: state(userID: otherUserID, status: .nearDestination)],
            displayNames: [:],
            currentUserID: currentUserID
        )
        XCTAssertEqual(fake.scheduledRequests.count, 1)

        // Flaps back to onTheWay, then back to nearDestination 10s later —
        // still within the 5-minute cooldown, must not re-notify.
        clock = now.addingTimeInterval(5)
        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .nearDestination)],
            updated: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        clock = now.addingTimeInterval(10)
        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            updated: [otherUserID: state(userID: otherUserID, status: .nearDestination)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        XCTAssertEqual(fake.scheduledRequests.count, 1, "Re-entering nearDestination within the cooldown window should not fire a second notification")
    }

    func testNotifyTransitions_afterCooldownExpires_notifiesAgain() {
        var clock = now
        let fake = FakeNotificationScheduling()
        let service = TripNotificationService(center: fake, cooldown: 300, now: { clock })

        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            updated: [otherUserID: state(userID: otherUserID, status: .delayed)],
            displayNames: [:],
            currentUserID: currentUserID
        )
        XCTAssertEqual(fake.scheduledRequests.count, 1)

        clock = now.addingTimeInterval(301)
        service.notifyTransitions(
            previous: [otherUserID: state(userID: otherUserID, status: .onTheWay)],
            updated: [otherUserID: state(userID: otherUserID, status: .delayed)],
            displayNames: [:],
            currentUserID: currentUserID
        )

        XCTAssertEqual(fake.scheduledRequests.count, 2)
    }
}
