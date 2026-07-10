import CloudKit
import Foundation

enum TripInviteRecordMapper: CloudKitRecordMappable {
    static let recordType = "TripInvite"
    enum Field {
        static let code = "code"
        static let shareURL = "shareURL"
        static let createdAt = "createdAt"
    }

    static func makeRecord(from model: TripInvite, recordID: CKRecord.ID? = nil) -> CKRecord {
        let record = makeRecord(with: model.id)
        record[Field.code] = model.code as CKRecordValue
        record[Field.shareURL] = model.shareURL.absoluteString as CKRecordValue
        record[Field.createdAt] = model.createdAt as CKRecordValue
        return record
    }

    static func makeModel(from record: CKRecord) throws -> TripInvite {
        guard
            let code = record[Field.code] as? String,
            let shareURLString = record[Field.shareURL] as? String,
            let shareURL = URL(string: shareURLString),
            let createdAt = record[Field.createdAt] as? Date
        else {
            throw CloudKitError.invalidRecord
        }
        return TripInvite(
            id: record.recordID,
            code: code,
            shareURL: shareURL,
            createdAt: createdAt
        )
    }
}
