//
//  LocationRecordMapperTests.swift
//  OmaweTests
//

import XCTest
import CloudKit
@testable import Omawe

final class LocationRecordMapperTests: XCTestCase {

    func testRoundTrip_preservesAllFields() throws {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)

        let sample = LocationSample(
            id: recordID,
            tripID: tripID,
            userID: userID,
            latitude: -6.2,
            longitude: 106.8,
            horizontalAccuracy: 12.5,
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let record = LocationRecordMapper.makeRecord(from: sample, recordID: recordID)
        let roundTripped = try LocationRecordMapper.makeModel(from: record)

        XCTAssertEqual(roundTripped.tripID, tripID)
        XCTAssertEqual(roundTripped.userID, userID)
        XCTAssertEqual(roundTripped.latitude, sample.latitude)
        XCTAssertEqual(roundTripped.longitude, sample.longitude)
        XCTAssertEqual(roundTripped.horizontalAccuracy, sample.horizontalAccuracy)
        XCTAssertEqual(roundTripped.recordedAt, sample.recordedAt)
    }

    func testRoundTrip_nilHorizontalAccuracy_staysNil() throws {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)

        let sample = LocationSample(
            id: recordID,
            tripID: tripID,
            userID: userID,
            latitude: 1,
            longitude: 2,
            horizontalAccuracy: nil,
            recordedAt: .now
        )

        let record = LocationRecordMapper.makeRecord(from: sample, recordID: recordID)
        let roundTripped = try LocationRecordMapper.makeModel(from: record)

        XCTAssertNil(roundTripped.horizontalAccuracy)
    }

    func testMakeRecord_setsParentReferenceToTripForSharedZoneWrites() {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let tripID = CKRecord.ID(recordName: "trip-1", zoneID: zoneID)
        let userID = CKRecord.ID(recordName: "user-1")
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)

        let sample = LocationSample(
            id: recordID,
            tripID: tripID,
            userID: userID,
            latitude: 1,
            longitude: 2,
            horizontalAccuracy: nil,
            recordedAt: .now
        )

        let record = LocationRecordMapper.makeRecord(from: sample, recordID: recordID)

        XCTAssertEqual(record.parent?.recordID, tripID)
    }

    func testMakeModel_missingRequiredField_throwsInvalidRecord() {
        let zoneID = CKRecordZone.ID(zoneName: "Trip-test-zone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: LocationRecordMapper.recordType, recordID: recordID)
        // Intentionally leave required fields unset.

        XCTAssertThrowsError(try LocationRecordMapper.makeModel(from: record)) { error in
            guard case .invalidRecord = error as? CloudKitError else {
                XCTFail("Expected CloudKitError.invalidRecord, got \(error)")
                return
            }
        }
    }
}
