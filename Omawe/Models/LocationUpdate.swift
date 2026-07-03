//
//  LocationUpdate.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import Foundation
import SwiftData

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
