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
    private let analytics: AnalyticsLogging

    init(analytics: AnalyticsLogging = AnalyticsService.shared) {
        self.analytics = analytics
    }

    /// NFR-3: retries the actual CloudKit write through `RetryExecutor`
    /// before this method ever throws — a single transient failure (network
    /// blip, momentary throttling) used to be a dead end here; now it's
    /// retried with backoff, classified against real `CKError.Code` values,
    /// while the error is still a `CKError` (retrying has to happen before
    /// `mapCKError` below converts it to the caller-facing `CloudKitError`,
    /// which doesn't carry enough information to reclassify). Reports the
    /// success/failure-with-attempt-count metric NFR-3 requires to actually
    /// verify the 99% sync-success target, not just assume it.
    func saveLocation(_ location: LocationSample) async throws {
        // Deterministic per-(trip, user) record name — this is an upsert
        // (`savePolicy: .changedKeys` below), not an insert. A fresh UUID
        // per save used to leave every prior sample in the zone forever, so
        // `fetchLatestLocations` scanned the trip's entire location history
        // on every poll tick — a query that only got slower the longer a
        // trip ran. One record per participant keeps that query O(participant
        // count) for the whole trip instead of O(samples ever written).
        let recordID = CKRecord.ID(
            recordName: "location-\(location.tripID.recordName)-\(location.userID.recordName)",
            zoneID: location.tripID.zoneID
        )

        let record = LocationRecordMapper.makeRecord(from: location, recordID: recordID)
        var attempts = 0

        do {
            let targetDatabase = try await databaseForZone(location.tripID.zoneID)
            try await RetryExecutor.run {
                attempts += 1
                _ = try await targetDatabase.modifyRecords(
                    saving: [record],
                    deleting: [],
                    savePolicy: .changedKeys
                )
            }
            analytics.log(.locationSyncResult(succeeded: true, attempts: attempts))
        } catch let error as CKError {
            analytics.log(.locationSyncResult(succeeded: false, attempts: attempts))
            throw mapCKError(error)
        } catch {
            analytics.log(.locationSyncResult(succeeded: false, attempts: attempts))
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
                        debugLog("[CloudKitLocationSyncService] Skipping unreadable LocationSample record \(record.recordID.recordName): \(error)")
                        return nil
                    }
                case .failure(let error):
                    debugLog("[CloudKitLocationSyncService] Match failure: \(error)")
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
