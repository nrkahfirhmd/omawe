import CloudKit

protocol LocationSyncServiceProtocol {
    func saveLocation(_ location: LocationSample) async throws
    func fetchLatestLocations(for tripID: CKRecord.ID) async throws -> [CKRecord.ID: LocationSample]
    func subscribeToLocationUpdates(for tripID: CKRecord.ID) async throws
}

/// Manual CKRecord sync path for location updates. this type only talks to
/// CloudKit, never CLLocationManager.
final class CloudKitLocationSyncService: LocationSyncServiceProtocol {
    private let privateDatabase = CloudKitContainer.shared.privateDatabase
    private let sharedDatabase = CloudKitContainer.shared.sharedDatabase
    private let identityService = CloudKitIdentityService()
    private let analytics: AnalyticsLogging

    init(analytics: AnalyticsLogging = AnalyticsService.shared) {
        self.analytics = analytics
    }

    func saveLocation(_ location: LocationSample) async throws {
        let recordID = CKRecord.ID(
            recordName: UUID().uuidString,
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
        query.sortDescriptors = [NSSortDescriptor(key: LocationRecordMapper.Field.recordedAt, ascending: false)]

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
    /// new location records via silent push. 
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

    /// One sample per user, keeping the most recent — but an older
    /// `reportedLateAt` still carries forward if the newest sample lacks one.
    static func latestByUser(from samples: [LocationSample]) -> [CKRecord.ID: LocationSample] {
        // Most recent reportedLateAt per user across all samples.
        var latestReportedLate: [CKRecord.ID: Date] = [:]
        for sample in samples {
            if let reportedAt = sample.reportedLateAt {
                if let existing = latestReportedLate[sample.userID] {
                    if reportedAt > existing {
                        latestReportedLate[sample.userID] = reportedAt
                    }
                } else {
                    latestReportedLate[sample.userID] = reportedAt
                }
            }
        }

        // Second pass: pick the latest sample per user by recordedAt
        var latest: [CKRecord.ID: LocationSample] = [:]
        for sample in samples {
            if let existing = latest[sample.userID], existing.recordedAt >= sample.recordedAt {
                continue
            }
            latest[sample.userID] = sample
        }

        // Third pass: carry forward reportedLateAt if the winning sample doesn't have it
        for (userID, reportedAt) in latestReportedLate {
            if var sample = latest[userID], sample.reportedLateAt == nil {
                sample.reportedLateAt = reportedAt
                latest[userID] = sample
            }
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
