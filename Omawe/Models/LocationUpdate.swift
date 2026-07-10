import Foundation
import SwiftData
import CloudKit

@Model
final class LocationUpdate {
    var id: UUID = UUID()

    // Stored as plain fields — CKRecord.ID/CKRecordZone.ID aren't natively
    // SwiftData-persistable types — and reassembled via the computed
    // `tripID`/`userID` below so callers never do ad hoc string conversion.
    var tripRecordName: String = ""
    var tripZoneName: String = ""
    var tripZoneOwnerName: String = ""
    var userRecordName: String = ""

    var latitude: Double = 0
    var longitude: Double = 0
    var horizontalAccuracy: Double?
    var recordedAt: Date = Date()
    var createdAt: Date = Date()
    var reportedLateAt: Date?

    /// False until `LocationUpdateQueueService.flush` confirms the CloudKit
    /// save succeeded. Lets a relaunch resume draining the queue without
    /// re-sending already-synced entries.
    var isSynced: Bool = false

    init(
        id: UUID = UUID(),
        tripID: CKRecord.ID,
        userID: CKRecord.ID,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double? = nil,
        recordedAt: Date = .now,
        createdAt: Date = .now,
        reportedLateAt: Date? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.tripRecordName = tripID.recordName
        self.tripZoneName = tripID.zoneID.zoneName
        self.tripZoneOwnerName = tripID.zoneID.ownerName
        self.userRecordName = userID.recordName
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.reportedLateAt = reportedLateAt
        self.isSynced = isSynced
    }

    var tripID: CKRecord.ID {
        CKRecord.ID(
            recordName: tripRecordName,
            zoneID: CKRecordZone.ID(zoneName: tripZoneName, ownerName: tripZoneOwnerName)
        )
    }

    var userID: CKRecord.ID {
        CKRecord.ID(recordName: userRecordName)
    }

    var asLocationSample: LocationSample {
        LocationSample(
            id: nil,
            tripID: tripID,
            userID: userID,
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: horizontalAccuracy,
            recordedAt: recordedAt,
            reportedLateAt: reportedLateAt
        )
    }
}
