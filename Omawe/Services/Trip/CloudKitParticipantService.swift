
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

            return try result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return try ParticipantRecordMapper.makeModel(from: record)
                case .failure:
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

    func updateParticipant(_ participant: Participant) async throws -> Participant {
        let record = ParticipantRecordMapper.makeRecord(from: participant)

        do {
            let targetDatabase = try await databaseForZone(participant.tripID.zoneID)
            let savedRecord = try await targetDatabase.save(record)
            return try ParticipantRecordMapper.makeModel(from: savedRecord)
        } catch {
            throw CloudKitError.unknown(error)
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

