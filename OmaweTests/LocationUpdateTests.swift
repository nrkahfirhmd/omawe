//
//  LocationUpdateTests.swift
//  OmaweTests
//

import XCTest
import CloudKit
@testable import Omawe

final class LocationUpdateTests: XCTestCase {

    func testTripIDAndUserID_roundTripThroughStoredFields() {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")

        let update = LocationUpdate(
            tripID: tripID,
            userID: userID,
            latitude: -6.2,
            longitude: 106.8
        )

        XCTAssertEqual(update.tripID, tripID)
        XCTAssertEqual(update.userID, userID)
    }

    func testAsLocationSample_preservesAllFields() {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")
        let recordedAt = Date(timeIntervalSince1970: 1_700_000_000)

        let update = LocationUpdate(
            tripID: tripID,
            userID: userID,
            latitude: 1,
            longitude: 2,
            horizontalAccuracy: 5,
            recordedAt: recordedAt
        )

        let sample = update.asLocationSample

        XCTAssertEqual(sample.tripID, tripID)
        XCTAssertEqual(sample.userID, userID)
        XCTAssertEqual(sample.latitude, 1)
        XCTAssertEqual(sample.longitude, 2)
        XCTAssertEqual(sample.horizontalAccuracy, 5)
        XCTAssertEqual(sample.recordedAt, recordedAt)
    }
}
