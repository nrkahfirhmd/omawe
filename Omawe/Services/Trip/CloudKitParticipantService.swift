
import CloudKit

struct UserProfileDetails {
    let displayName: String?
    let avatarData: Data?
}

protocol ParticipantServiceProtocol {
    func createParticipant(_ participant: Participant) async throws -> Participant
    func fetchParticipants(for tripID: CKRecord.ID) async throws -> [Participant]
    func updateParticipant(_ participant: Participant) async throws -> Participant
    func removeParticipant(id: CKRecord.ID) async throws
    func fetchProfileDetails(for userID: CKRecord.ID) async -> UserProfileDetails?
}

final class CloudKitParticipantService: ParticipantServiceProtocol {

    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let publicDatabase = CloudKitContainer.shared.publicDatabase
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

    /// Fetches the current server record before saving 
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

    func fetchProfileDetails(for userID: CKRecord.ID) async -> UserProfileDetails? {
        let predicate = NSPredicate(format: "CD_userID == %@", userID.recordName)
        let query = CKQuery(recordType: "CD_UserProfile", predicate: predicate)
        
        let databasesWithZones: [(CKDatabase, CKRecordZone.ID)] = [
            (sharedDatabase, CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: userID.recordName)),
            (privateDatabase, CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName))
        ]
        
        for (db, zoneID) in databasesWithZones {
            do {
                let result = try await db.records(matching: query, inZoneWith: zoneID, resultsLimit: 1)
                if let record = try result.matchResults.first?.1.get() {
                    let displayName = record["CD_displayName"] as? String
                    var avatarData: Data? = nil
                    
                    if let asset = record["CD_avatarImageData_ckAsset"] as? CKAsset, let fileURL = asset.fileURL {
                        avatarData = try? Data(contentsOf: fileURL)
                    } else if let data = record["CD_avatarImageData"] as? Data {
                        avatarData = data
                    }
                    
                    return UserProfileDetails(displayName: displayName, avatarData: avatarData)
                }
            } catch {
                // Continue
            }
        }
        
        // Try public database (default zone query)
        do {
            let result = try await publicDatabase.records(matching: query, resultsLimit: 1)
            if let record = try result.matchResults.first?.1.get() {
                let displayName = record["CD_displayName"] as? String
                var avatarData: Data? = nil
                
                if let asset = record["CD_avatarImageData_ckAsset"] as? CKAsset, let fileURL = asset.fileURL {
                    avatarData = try? Data(contentsOf: fileURL)
                } else if let data = record["CD_avatarImageData"] as? Data {
                    avatarData = data
                }
                
                return UserProfileDetails(displayName: displayName, avatarData: avatarData)
            }
        } catch {
            // Ignore
        }
        
        return nil
    }
}

