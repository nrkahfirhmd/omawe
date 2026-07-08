//
//  ParticipantRecordMapper.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

struct ParticipantRecordMapper: CloudKitRecordMappable {
    static func makeRecord(
        from model: Participant,
        recordID: CKRecord.ID? = nil
    ) -> CKRecord {
        guard let recordID = recordID ?? model.id else {
            preconditionFailure("ParticipantRecordMapper requires a CKRecord.ID when creating a CKRecord.")
        }

        let record = makeRecord(with: recordID)

        record[Field.tripID] = model.tripID.recordName as CKRecordValue
        record[Field.userID] = model.userID.recordName as CKRecordValue
        record[Field.role] = model.role.rawValue as CKRecordValue
        record[Field.joinedAt] = model.joinedAt as CKRecordValue

        // Required for non-owner writes into a shared zone — CloudKit needs
        // to know this record's place in the share's hierarchy.
        record.parent = CKRecord.Reference(recordID: model.tripID, action: .none)

        return record
    }
    
    
    typealias Model = Participant

    static let recordType = "Participant"

    private enum Field {
        static let tripID = "tripID"
        static let userID = "userID"
        static let role = "role"
        static let joinedAt = "joinedAt"
    }

    static func makeModel(from record: CKRecord) throws -> Participant {
        guard
            let tripRecordName = record[Field.tripID] as? String,
            let userRecordName = record[Field.userID] as? String,
            let roleRawValue = record[Field.role] as? String,
            let role = ParticipantRole(rawValue: roleRawValue),
            let joinedAt = record[Field.joinedAt] as? Date
        else {
            throw CloudKitError.invalidRecord
        }

        let tripID = CKRecord.ID(recordName: tripRecordName, zoneID: record.recordID.zoneID)

        return Participant(
            id: record.recordID,
            tripID: tripID,
            userID: CKRecord.ID(recordName: userRecordName),
            role: role,
            joinedAt: joinedAt
        )
    }
}
