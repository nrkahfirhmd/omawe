import CloudKit

/// CloudKit-facing shape for a single location sample, written into the trip's shared custom zone 
struct LocationSample: Identifiable, Hashable {
    let id: CKRecord.ID?
    let tripID: CKRecord.ID
    let userID: CKRecord.ID
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double?
    var recordedAt: Date
    var reportedLateAt: Date?
}
