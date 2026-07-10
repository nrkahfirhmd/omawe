import CloudKit
import UIKit

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
        if let displayName = model.displayName {
            record[Field.displayName] = displayName as CKRecordValue
        }
        if let avatarImageData = model.avatarImageData {
            let compressed = compressImage(avatarImageData)
            record[Field.avatarImageData] = (compressed ?? avatarImageData) as CKRecordValue
        }

        // Required for non-owner writes into a shared zone — CloudKit needs
        // to know this record's place in the share's hierarchy.
        record.parent = CKRecord.Reference(recordID: model.tripID, action: .none)

        return record
    }

    private static func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let maxDimension: CGFloat = 200.0
        let size = image.size
        
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage.jpegData(compressionQuality: 0.6)
    }

    /// Applies `model`'s mutable fields onto an already-fetched `record` in
    /// place, preserving its `recordChangeTag`
    static func apply(_ model: Participant, to record: CKRecord) {
        record[Field.role] = model.role.rawValue as CKRecordValue
    }

    typealias Model = Participant

    static let recordType = "Participant"

    private enum Field {
        static let tripID = "tripID"
        static let userID = "userID"
        static let role = "role"
        static let joinedAt = "joinedAt"
        static let displayName = "displayName"
        static let avatarImageData = "avatarImageData"
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

        let displayName = record[Field.displayName] as? String
        let avatarImageData = record[Field.avatarImageData] as? Data

        let tripID = CKRecord.ID(recordName: tripRecordName, zoneID: record.recordID.zoneID)

        return Participant(
            id: record.recordID,
            tripID: tripID,
            userID: CKRecord.ID(recordName: userRecordName),
            displayName: displayName,
            role: role,
            joinedAt: joinedAt,
            avatarImageData: avatarImageData
        )
    }
}
