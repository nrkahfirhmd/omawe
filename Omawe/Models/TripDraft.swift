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
    var invitationCode: String = TripCreationService.makeInvitationCode()

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedLocationName: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canCreateTrip: Bool {
        !trimmedName.isEmpty && !trimmedLocationName.isEmpty
    }

    var creationInput: TripCreationInput {
        TripCreationInput(
            name: name,
            startDate: arrivalDate,
            meetTime: arrivalDate,
            locationName: locationName,
            locationAddress: locationAddress,
            locationNote: apartmentUnitFloor,
            locationDisplayName: locationNickname,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            invitationCode: invitationCode
        )
    }

    mutating func reset() {
        self = TripDraft()
    }
}
