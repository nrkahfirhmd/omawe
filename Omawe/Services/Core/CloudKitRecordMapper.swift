//
//  CloudKitRecordMapper.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

protocol CloudKitRecordMappable {
    associatedtype Model
    
    static var recordType: String { get }
    
    static func makeRecord(
        from model: Model,
        recordID: CKRecord.ID?
    ) -> CKRecord
    static func makeModel(from record: CKRecord) throws -> Model
}

extension CloudKitRecordMappable {
    static func makeRecord(with recordID: CKRecord.ID? = nil) -> CKRecord {
        if let recordID {
            return CKRecord(recordType: recordType, recordID: recordID)
        }
        return CKRecord(recordType: recordType)
    }
}
