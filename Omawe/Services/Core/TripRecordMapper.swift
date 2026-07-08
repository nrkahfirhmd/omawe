//
//  TripRecordMapper.swift.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

struct TripRecordMapper: CloudKitRecordMappable {
    typealias Model = Trip

    static let recordType = "Trip"

    enum Field {
        static let title = "title"
        static let destination = "destination"
        static let startDate = "startDate"
        static let endDate = "endDate"
        static let ownerID = "ownerID"
        static let ownerDisplayName = "ownerDisplayName"
        static let invitationCode = "invitationCode"
        static let status = "status"
        static let destinationLatitude = "destinationLatitude"
        static let destinationLongitude = "destinationLongitude"
        static let locationAddress = "locationAddress"
        static let apartmentUnitFloor = "apartmentUnitFloor"
        static let locationNickname = "locationNickname"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    static func makeRecord(from model: Trip, recordID: CKRecord.ID? = nil) -> CKRecord {

        guard let recordID = recordID ?? model.id else {
                preconditionFailure("TripRecordMapper requires a CKRecord.ID when creating a CKRecord.")
            }

        let record = makeRecord(with: recordID)
        apply(model, to: record)
        return record
    }

    /// Writes `model`'s fields onto an existing `CKRecord` in place, preserving
    /// that record's system metadata (change tag) so CloudKit treats the save
    /// as an update rather than a conflicting insert of an already-existing record.
    static func apply(_ model: Trip, to record: CKRecord) {
        record[Field.title] = model.title as CKRecordValue
        record[Field.destination] = model.destination as CKRecordValue
        record[Field.startDate] = model.startDate as CKRecordValue
        record[Field.endDate] = model.endDate as CKRecordValue
        record[Field.ownerID] = model.ownerID.recordName as CKRecordValue
        if let displayName = model.ownerDisplayName {
            record[Field.ownerDisplayName] = displayName as CKRecordValue
        }
        record[Field.invitationCode] = model.invitationCode as CKRecordValue
        record[Field.status] = model.status.rawValue as CKRecordValue
        if let destinationLatitude = model.destinationLatitude {
            record[Field.destinationLatitude] = destinationLatitude as CKRecordValue
        }
        if let destinationLongitude = model.destinationLongitude {
            record[Field.destinationLongitude] = destinationLongitude as CKRecordValue
        }
        if let locationAddress = model.locationAddress {
            record[Field.locationAddress] = locationAddress as CKRecordValue
        }
        if let apartmentUnitFloor = model.apartmentUnitFloor {
            record[Field.apartmentUnitFloor] = apartmentUnitFloor as CKRecordValue
        }
        if let locationNickname = model.locationNickname {
            record[Field.locationNickname] = locationNickname as CKRecordValue
        }
        record[Field.createdAt] = model.createdAt as CKRecordValue
        record[Field.updatedAt] = model.updatedAt as CKRecordValue
    }

    static func makeModel(from record: CKRecord) throws -> Trip {
        guard
            let title = record[Field.title] as? String,
            let destination = record[Field.destination] as? String,
            let startDate = record[Field.startDate] as? Date,
            let endDate = record[Field.endDate] as? Date,
            let ownerRecordName = record[Field.ownerID] as? String,
            let invitationCode = record[Field.invitationCode] as? String,
            let createdAt = record[Field.createdAt] as? Date,
            let updatedAt = record[Field.updatedAt] as? Date
        else {
            throw CloudKitError.invalidRecord
        }

        // Records saved before the status field existed have no value here —
        // default to .notStarted rather than failing the whole decode.
        let status = (record[Field.status] as? String).flatMap(TripStatus.init(rawValue:)) ?? .notStarted
        let ownerDisplayName = record[Field.ownerDisplayName] as? String
        let locationAddress = record[Field.locationAddress] as? String
        let apartmentUnitFloor = record[Field.apartmentUnitFloor] as? String
        let locationNickname = record[Field.locationNickname] as? String
 
        return Trip(
            id: record.recordID,
            title: title,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            ownerID: CKRecord.ID(recordName: ownerRecordName),
            ownerDisplayName: ownerDisplayName,
            invitationCode: invitationCode,
            status: status,
            destinationLatitude: record[Field.destinationLatitude] as? Double,
            destinationLongitude: record[Field.destinationLongitude] as? Double,
            locationAddress: locationAddress,
            apartmentUnitFloor: apartmentUnitFloor,
            locationNickname: locationNickname,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
