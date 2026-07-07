//
//  LocationUpdate.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import Foundation
import SwiftData

// LOC-1 finding, handed to LOC-4: this model's SwiftData+CloudKit auto-mirror
// (see the `cloudKitDatabase` config in OmaweApp.swift) writes into the
// record owner's default private zone, not the trip's shared custom zone —
// it has no path to other participants and cannot be the cross-device sync
// transport (see CloudKitLocationSyncService). LOC-1 bypasses it with a
// manual CKRecord save. LOC-4 should decide: disable CloudKit mirroring for
// this model (move it to a local-only ModelConfiguration) or keep mirroring
// and repurpose this type as a local offline cache only.
@Model
final class LocationUpdate {
    var id: UUID = UUID()
    var tripID: UUID = UUID()
    var userID: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var horizontalAccuracy: Double?
    var recordedAt: Date = Date()
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        tripID: UUID,
        userID: String,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double? = nil,
        recordedAt: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.tripID = tripID
        self.userID = userID
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.recordedAt = recordedAt
        self.createdAt = createdAt
    }
}
