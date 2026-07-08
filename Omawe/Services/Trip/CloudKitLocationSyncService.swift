//
//  CloudKitLocationSyncService.swift
//  Omawe
//

import CloudKit

protocol LocationSyncServiceProtocol {
    func saveLocation(_ location: LocationSample) async throws
    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: LocationSample]
    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws
}

/// Manual CKRecord sync path for location updates. Named to avoid colliding
/// with LOC-2's CoreLocation-facing service — this type only talks to
/// CloudKit, never CLLocationManager.
///
/// SwiftData's automatic CloudKit mirroring on `LocationUpdate` (configured
/// in OmaweApp.swift) writes into the record owner's default private zone,
/// which is a different zone from the trip's custom `CKRecordZone` that
/// `CKShare` grants access to. That auto-mirror therefore cannot reach other
/// participants, so this service saves directly into the trip's zone instead.
final class CloudKitLocationSyncService: LocationSyncServiceProtocol {

    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let identityService = CloudKitIdentityService()

    func saveLocation(_ location: LocationSample) async throws {
        let recordID = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: location.tripID.zoneID
        )

        let record = LocationRecordMapper.makeRecord(from: location, recordID: recordID)

        do {
            let targetDatabase = try await databaseForZone(location.tripID.zoneID)
            _ = try await targetDatabase.modifyRecords(
                saving: [record],
                deleting: [],
                savePolicy: .changedKeys
            )
        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: LocationSample] {
        let predicate = NSPredicate(format: "tripID == %@", tripID.recordName)
        let query = CKQuery(recordType: LocationRecordMapper.recordType, predicate: predicate)

        do {
            let targetDatabase = try await databaseForZone(tripID.zoneID)

            let result = try await targetDatabase.records(
                matching: query,
                inZoneWith: tripID.zoneID
            )

            let samples = result.matchResults.compactMap { _, matchResult -> LocationSample? in
                switch matchResult {
                case .success(let record):
                    do {
                        return try LocationRecordMapper.makeModel(from: record)
                    } catch {
                        print("[CloudKitLocationSyncService] Skipping unreadable LocationSample record \(record.recordID.recordName): \(error)")
                        return nil
                    }
                case .failure(let error):
                    print("[CloudKitLocationSyncService] Match failure: \(error)")
                    return nil
                }
            }

            return Self.latestByUser(from: samples)
        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    /// Zone-scoped subscription so other participants' devices learn about
    /// new location records via silent push. Per the plan, treat delivery as
    /// best-effort — not guaranteed real-time under Low Power Mode/background
    /// throttling — and complement with polling if manual testing shows the
    /// 30s budget is missed.
    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws {
        let subscriptionID = "location-updates-\(tripID.zoneID.zoneName)"
        let predicate = NSPredicate(format: "tripID == %@", tripID.recordName)

        let subscription = CKQuerySubscription(
            recordType: LocationRecordMapper.recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            let targetDatabase = try await databaseForZone(tripID.zoneID)
            _ = try await targetDatabase.modifySubscriptions(saving: [subscription], deleting: [])
        } catch let error as CKError {
            throw mapCKError(error)
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

    /// Pure reduction: one sample per user, keeping the most recently
    /// recorded one. Pulled out of `fetchLatestLocations` so the tie-break
    /// logic is unit-testable without live CloudKit.
    static func latestByUser(from samples: [LocationSample]) -> [CKRecord.ID: LocationSample] {
        var latest: [CKRecord.ID: LocationSample] = [:]
        for sample in samples {
            if let existing = latest[sample.userID], existing.recordedAt >= sample.recordedAt {
                continue
            }
            latest[sample.userID] = sample
        }
        return latest
    }

    private func mapCKError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .zoneNotFound, .userDeletedZone:
            return .recordNotFound
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        default:
            return .unknown(error)
        }
    }
}
