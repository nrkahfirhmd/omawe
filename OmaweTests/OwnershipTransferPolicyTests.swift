import XCTest
import CloudKit
@testable import Omawe

final class OwnershipTransferPolicyTests: XCTestCase {

    private let tripID = CKRecord.ID(recordName: "trip-1")
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func participant(_ name: String, role: ParticipantRole, joinedSecondsAgo: TimeInterval) -> Participant {
        Participant(
            id: CKRecord.ID(recordName: name),
            tripID: tripID,
            userID: CKRecord.ID(recordName: "user-\(name)"),
            displayName: name,
            role: role,
            joinedAt: now.addingTimeInterval(-joinedSecondsAgo)
        )
    }

    func testSelectNewOwner_picksEarliestJoinedAmongRemaining() {
        let remaining = [
            participant("late", role: .member, joinedSecondsAgo: 10),
            participant("earliest", role: .member, joinedSecondsAgo: 1_000),
            participant("middle", role: .member, joinedSecondsAgo: 100)
        ]

        let selected = OwnershipTransferPolicy.selectNewOwner(remaining: remaining)

        XCTAssertEqual(selected?.displayName, "earliest")
    }

    func testSelectNewOwner_noRemainingParticipants_returnsNil() {
        XCTAssertNil(OwnershipTransferPolicy.selectNewOwner(remaining: []))
    }

    func testSelectNewOwner_earliestAlreadyOwner_returnsNil() {
        // A racing device already completed the transfer — this call should
        // be a no-op, not attempt a second promotion.
        let remaining = [
            participant("already-owner", role: .owner, joinedSecondsAgo: 1_000),
            participant("member", role: .member, joinedSecondsAgo: 10)
        ]

        XCTAssertNil(OwnershipTransferPolicy.selectNewOwner(remaining: remaining))
    }
}
