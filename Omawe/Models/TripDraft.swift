//
//  TripDraft.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import Foundation
import CoreLocation

struct TripDraft {
    var name: String = ""
    var arrivalDate: Date = Date()
    var locationName: String = ""
    var locationAddress: String = ""
    var apartmentUnitFloor: String = ""
    var locationNickname: String = ""
    var coordinate: CLLocationCoordinate2D?
    var invitationCode: String = ""

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedLocationName: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canCreateTrip: Bool {
        !trimmedName.isEmpty && !trimmedLocationName.isEmpty
    }

    mutating func reset() {
        self = TripDraft()
    }
}
