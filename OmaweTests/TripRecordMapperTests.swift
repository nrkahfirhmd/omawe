import XCTest
import CloudKit
@testable import Omawe

final class TripRecordMapperTests: XCTestCase {

    private func makeTrip(
        recordID: CKRecord.ID,
        destinationLatitude: Double? = nil,
        destinationLongitude: Double? = nil
    ) -> Trip {
        Trip(
            id: recordID,
            title: "Ex-Boyfriends Celebration",
            destination: "Toko Kopi Jaya, Kuta",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_003_600),
            ownerID: CKRecord.ID(recordName: "owner-1"),
            invitationCode: "1A6B7K",
            status: .active,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude,
            createdAt: .now,
            updatedAt: .now
        )
    }

    func testRoundTrip_preservesDestinationCoordinate() throws {
        let recordID = CKRecord.ID(recordName: "trip-1")
        let trip = makeTrip(recordID: recordID, destinationLatitude: -8.7181, destinationLongitude: 115.1683)

        let record = TripRecordMapper.makeRecord(from: trip, recordID: recordID)
        let roundTripped = try TripRecordMapper.makeModel(from: record)

        XCTAssertEqual(roundTripped.destinationLatitude, -8.7181)
        XCTAssertEqual(roundTripped.destinationLongitude, 115.1683)
        XCTAssertNotNil(roundTripped.destinationCoordinate)
        XCTAssertEqual(roundTripped.destinationCoordinate?.latitude, -8.7181)
        XCTAssertEqual(roundTripped.destinationCoordinate?.longitude, 115.1683)
    }

    func testRoundTrip_missingDestinationCoordinate_decodesAsNilNotFailure() throws {
        let recordID = CKRecord.ID(recordName: "trip-1")
        let trip = makeTrip(recordID: recordID)

        let record = TripRecordMapper.makeRecord(from: trip, recordID: recordID)
        let roundTripped = try TripRecordMapper.makeModel(from: record)

        XCTAssertNil(roundTripped.destinationLatitude)
        XCTAssertNil(roundTripped.destinationLongitude)
        XCTAssertNil(roundTripped.destinationCoordinate)
    }

    func testMakeModel_recordSavedBeforeCoordinateFieldExisted_decodesWithoutThrowing() throws {
        // Simulates a legacy record written before this ticket: no
        // destinationLatitude/Longitude keys present at all.
        let recordID = CKRecord.ID(recordName: "trip-1")
        let record = CKRecord(recordType: TripRecordMapper.recordType, recordID: recordID)
        record["title"] = "Legacy Trip" as CKRecordValue
        record["destination"] = "Somewhere" as CKRecordValue
        record["startDate"] = Date(timeIntervalSince1970: 1_700_000_000) as CKRecordValue
        record["endDate"] = Date(timeIntervalSince1970: 1_700_003_600) as CKRecordValue
        record["ownerID"] = "owner-1" as CKRecordValue
        record["invitationCode"] = "1A6B7K" as CKRecordValue
        record["createdAt"] = Date(timeIntervalSince1970: 1_700_000_000) as CKRecordValue
        record["updatedAt"] = Date(timeIntervalSince1970: 1_700_000_000) as CKRecordValue

        let model = try TripRecordMapper.makeModel(from: record)

        XCTAssertEqual(model.status, .notStarted)
        XCTAssertNil(model.destinationCoordinate)
    }
}
