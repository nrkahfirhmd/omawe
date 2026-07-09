//
//  LocationSample.swift
//  Omawe
//

import CloudKit

/// CloudKit-facing shape for a single location sample, written into the
/// trip's shared custom zone (see LocationRecordMapper). Distinct from
/// `LocationUpdate` (SwiftData's local/auto-mirrored model, owned by LOC-4)
/// and from `Location` (the plain lat/lng value type used by LocationCore).
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
