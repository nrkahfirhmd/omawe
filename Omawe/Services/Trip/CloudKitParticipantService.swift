
//
//  CloudKitParticipantService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

protocol ParticipantServiceProtocol {
    func createParticipant(_ participant: Participant) async throws -> Participant
    func fetchParticipants(for tripID: CKRecord.ID) async throws -> [Participant]
    func updateParticipant(_ participant: Participant) async throws -> Participant
    func removeParticipant(id: CKRecord.ID) async throws
}

final class CloudKitParticipantService: ParticipantServiceProtocol {

    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let identityService = CloudKitIdentityService()

    func createParticipant(_ participant: Participant) async throws -> Participant {
        let participantRecordID = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: participant.tripID.zoneID
        )

        let participantRecord = ParticipantRecordMapper.makeRecord(
            from: participant,
            recordID: participantRecordID
        )

        do {
            let targetDatabase = try await databaseForZone(participant.tripID.zoneID)
            let savedRecord = try await targetDatabase.save(participantRecord)
            return try ParticipantRecordMapper.makeModel(from: savedRecord)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func fetchParticipants(for tripID: CKRecord.ID) async throws -> [Participant] {
        let predicate = NSPredicate(format: "tripID == %@", tripID.recordName)
        let query = CKQuery(recordType: ParticipantRecordMapper.recordType, predicate: predicate)

        do {
            let targetDatabase = try await databaseForZone(tripID.zoneID)

            let result = try await targetDatabase.records(
                matching: query,
                inZoneWith: tripID.zoneID
            )

            return result.matchResults.compactMap { _, result -> Participant? in
                switch result {
                case .success(let record):
                    do {
                        return try ParticipantRecordMapper.makeModel(from: record)
                    } catch {
                        debugLog("[CloudKitParticipantService] Skipping unreadable Participant record \(record.recordID.recordName): \(error)")
                        return nil
                    }
                case .failure(let error):
                    debugLog("[CloudKitParticipantService] Match failure: \(error)")
                    return nil
                }
            }
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    /// Determines whether a zone belongs to the current user (private DB)
    /// or was shared to them by someone else (shared DB).
    private func databaseForZone(_ zoneID: CKRecordZone.ID) async throws -> CKDatabase {
        let currentUserID = try await identityService.currentUserRecordID()

        if zoneID.ownerName == currentUserID.recordName || zoneID.ownerName == CKCurrentUserDefaultName {
            return privateDatabase
        } else {
            return sharedDatabase
        }
    }

    /// Fetches the current server record before saving rather than
    /// blind-constructing a fresh `CKRecord`: a freshly-constructed record
    /// carries no `recordChangeTag`, so CloudKit has nothing to compare
    /// against and a save silently overwrites whatever's on the server —
    /// last-write-wins with no guard. Fetching first gives the record a real
    /// change tag, so the explicit `.ifServerRecordUnchanged` save below
    /// actually rejects a concurrent write (`CKError.serverRecordChanged`)
    /// instead of racing it silently. This is TRIP-2's concurrent-leave guard.
    func updateParticipant(_ participant: Participant) async throws -> Participant {
        guard let recordID = participant.id else { throw CloudKitError.invalidRecord }

        do {
            let targetDatabase = try await databaseForZone(participant.tripID.zoneID)
            let currentRecord = try await targetDatabase.record(for: recordID)
            ParticipantRecordMapper.apply(participant, to: currentRecord)

            let savedRecord = try await saveConflictSafe(currentRecord, to: targetDatabase)
            return try ParticipantRecordMapper.makeModel(from: savedRecord)
        } catch let error as CKError where error.code == .serverRecordChanged {
            throw CloudKitError.conflict
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    private func saveConflictSafe(_ record: CKRecord, to database: CKDatabase) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.savePolicy = .ifServerRecordUnchanged
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: record)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    func removeParticipant(id: CKRecord.ID) async throws {
        do {
            let targetDatabase = try await databaseForZone(id.zoneID)
            _ = try await targetDatabase.deleteRecord(withID: id)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}

