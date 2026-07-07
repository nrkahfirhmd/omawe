//
//  LocationRecordMapper.swift
//  Omawe
//

import CloudKit

struct LocationRecordMapper: CloudKitRecordMappable {
    typealias Model = LocationSample

    static let recordType = "LocationUpdate"

    enum Field {
        static let tripID = "tripID"
        static let userID = "userID"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let horizontalAccuracy = "horizontalAccuracy"
        static let recordedAt = "recordedAt"
    }

    static func makeRecord(
        from model: LocationSample,
        recordID: CKRecord.ID? = nil
    ) -> CKRecord {
        guard let recordID = recordID ?? model.id else {
            preconditionFailure("LocationRecordMapper requires a CKRecord.ID when creating a CKRecord.")
        }

        let record = makeRecord(with: recordID)

        record[Field.tripID] = model.tripID.recordName as CKRecordValue
        record[Field.userID] = model.userID.recordName as CKRecordValue
        record[Field.latitude] = model.latitude as CKRecordValue
        record[Field.longitude] = model.longitude as CKRecordValue
        record[Field.recordedAt] = model.recordedAt as CKRecordValue
        if let horizontalAccuracy = model.horizontalAccuracy {
            record[Field.horizontalAccuracy] = horizontalAccuracy as CKRecordValue
        }

        // Required for non-owner writes into a shared zone — CloudKit needs
        // to know this record's place in the share's hierarchy.
        record.parent = CKRecord.Reference(recordID: model.tripID, action: .none)

        return record
    }

    static func makeModel(from record: CKRecord) throws -> LocationSample {
        guard
            let tripRecordName = record[Field.tripID] as? String,
            let userRecordName = record[Field.userID] as? String,
            let latitude = record[Field.latitude] as? Double,
            let longitude = record[Field.longitude] as? Double,
            let recordedAt = record[Field.recordedAt] as? Date
        else {
            throw CloudKitError.invalidRecord
        }

        let tripID = CKRecord.ID(recordName: tripRecordName, zoneID: record.recordID.zoneID)

        return LocationSample(
            id: record.recordID,
            tripID: tripID,
            userID: CKRecord.ID(recordName: userRecordName),
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: record[Field.horizontalAccuracy] as? Double,
            recordedAt: recordedAt
        )
    }
}
