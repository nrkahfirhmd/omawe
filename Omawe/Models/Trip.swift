//
//  Trip.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import SwiftUI
import CloudKit
import CoreLocation

struct Trip : Identifiable, Hashable {
    let id: CKRecord.ID?
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    let ownerID: CKRecord.ID
    var ownerDisplayName: String?
    var invitationCode: String
    var status: TripStatus = .notStarted
    /// Captured once at trip creation from `TripDraft.coordinate` (LOC's
    /// MapKit destination search). Nil for trips created before this field
    /// existed, or if the destination was typed without picking a search
    /// result — callers must re-geocode `destination` as a fallback in that case.
    var destinationLatitude: Double?
    var destinationLongitude: Double?
    var createdAt: Date
    var updatedAt: Date

    var destinationCoordinate: CLLocationCoordinate2D? {
        guard let destinationLatitude, let destinationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
}

enum TripStatus: String, Codable {
    case notStarted
    case active
    case ended
}
