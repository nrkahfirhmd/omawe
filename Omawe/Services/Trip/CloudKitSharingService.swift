
import CloudKit
import Foundation

protocol SharingServiceProtocol {
    func createShare(for tripID: CKRecord.ID) async throws -> (CKShare, URL)
    func acceptShare(from url: URL) async throws -> CKRecord.ID
    func acceptShare(_ metadata: CKShare.Metadata) async throws -> CKRecord.ID
    func fetchSharedTrips() async throws -> [Trip]
}

final class CloudKitSharingService: SharingServiceProtocol {
    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase

    func createShare(for tripID: CKRecord.ID) async throws -> (CKShare, URL) {
        do {
            debugLog("Share Trip Zone:", tripID.zoneID.zoneName)
            let tripRecord = try await privateDatabase.record(for: tripID)

            let share = CKShare(rootRecord: tripRecord)
            share.publicPermission = .readWrite
            share[CKShare.SystemFieldKey.title] =
                (tripRecord[TripRecordMapper.Field.title] as? NSString) ?? "Trip"

            debugLog("📤 Creating CKShare:", share.recordID.recordName)
            let result = try await privateDatabase.modifyRecords(
                saving: [tripRecord, share],
                deleting: []
            )

            guard let shareResult = result.saveResults[share.recordID] else {
                throw CloudKitError.operationFailed
            }

            switch shareResult {
            case .success(let record):
                guard let savedShare = record as? CKShare,
                      let url = savedShare.url else {
                    throw CloudKitError.operationFailed
                }
                debugLog("✅ Share created")
                debugLog("Permission:", savedShare.publicPermission.rawValue)
                debugLog("URL:", url.absoluteString)
                return (savedShare, url)

            case .failure(let error):
                debugLog("❌ Share creation failed:", error)
                throw CloudKitError.unknown(error)
            }
        } catch let error as CloudKitError {
            throw error
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func acceptShare(from url: URL) async throws -> CKRecord.ID {
        debugLog("📥 Fetching share metadata:", url.absoluteString)
        let metadata: CKShare.Metadata = try await withCheckedThrowingContinuation { continuation in
            CloudKitContainer.shared.container.fetchShareMetadata(with: url) { metadata, error in
                if let error {
                    debugLog("❌ Metadata fetch failed:", error)
                    continuation.resume(throwing: error)
                } else if let metadata {
                    debugLog("✅ Share metadata fetched")
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: CloudKitError.operationFailed)
                }
            }
        }
        return try await acceptShare(metadata)
    }

    func acceptShare(_ metadata: CKShare.Metadata) async throws -> CKRecord.ID {
        do {
            debugLog("🤝 Accepting CloudKit share...")
            try await CloudKitContainer.shared.container.accept(metadata)
            debugLog("✅ CloudKit share accepted")

            return metadata.rootRecordID
        } catch {
            debugLog("❌ Accept share failed:", error)
            throw CloudKitError.unknown(error)
        }
    }

    func fetchSharedTrips() async throws -> [Trip] {
        do {
            let zones = try await sharedDatabase.allRecordZones()

            return try await withThrowingTaskGroup(of: [Trip].self) { group in
                for zone in zones {
                    group.addTask {
                        let query = CKQuery(
                            recordType: TripRecordMapper.recordType,
                            predicate: NSPredicate(value: true)
                        )

                        let result = try await self.sharedDatabase.records(
                            matching: query,
                            inZoneWith: zone.zoneID
                        )

                        return result.matchResults.compactMap { _, matchResult -> Trip? in
                            switch matchResult {
                            case .success(let record):
                                do {
                                    return try TripRecordMapper.makeModel(from: record)
                                } catch {
                                    debugLog("[CloudKitSharingService] Skipping unreadable Trip record \(record.recordID.recordName): \(error)")
                                    return nil
                                }
                            case .failure(let error):
                                debugLog("[CloudKitSharingService] Match failure in zone \(zone.zoneID.zoneName): \(error)")
                                return nil
                            }
                        }
                    }
                }

                var trips: [Trip] = []
                for try await zoneTrips in group {
                    trips.append(contentsOf: zoneTrips)
                }
                return trips
            }
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
