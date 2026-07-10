import XCTest
import CloudKit
@testable import Omawe

final class CloudKitLocationSyncServiceTests: XCTestCase {

    private let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
    private lazy var tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)

    private func sample(user: String, secondsAgo: TimeInterval) -> LocationSample {
        LocationSample(
            id: nil,
            tripID: tripID,
            userID: CKRecord.ID(recordName: user),
            latitude: 0,
            longitude: 0,
            horizontalAccuracy: nil,
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000 - secondsAgo)
        )
    }

    func testLatestByUser_keepsMostRecentSamplePerUser() {
        let older = sample(user: "user-1", secondsAgo: 100)
        let newer = sample(user: "user-1", secondsAgo: 0)

        let result = CloudKitLocationSyncService.latestByUser(from: [older, newer])

        XCTAssertEqual(result[newer.userID]?.recordedAt, newer.recordedAt)
    }

    func testLatestByUser_keepsOneEntryPerDistinctUser() {
        let userOne = sample(user: "user-1", secondsAgo: 0)
        let userTwo = sample(user: "user-2", secondsAgo: 0)

        let result = CloudKitLocationSyncService.latestByUser(from: [userOne, userTwo])

        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result[userOne.userID])
        XCTAssertNotNil(result[userTwo.userID])
    }

    func testLatestByUser_emptyInput_returnsEmpty() {
        XCTAssertTrue(CloudKitLocationSyncService.latestByUser(from: []).isEmpty)
    }

    func testLatestByUser_tie_keepsFirstEncountered() {
        let first = sample(user: "user-1", secondsAgo: 0)
        let tiedSecond = sample(user: "user-1", secondsAgo: 0)

        let result = CloudKitLocationSyncService.latestByUser(from: [first, tiedSecond])

        XCTAssertEqual(result.count, 1)
    }
}
