//
//  TripModel.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 30/06/26.
//

import Foundation
import SwiftData

@Model
final class TripModel {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var meetTime: Date = Date()
    var locationName: String = ""
    var locationAddress: String?
    var locationNote: String?
    var locationDisplayName: String?
    var latitude: Double?
    var longitude: Double?
    var ownerUserID: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var memberIdentifiers: [String] = []
    var invitationCode: String?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        meetTime: Date,
        locationName: String,
        locationAddress: String? = nil,
        locationNote: String? = nil,
        locationDisplayName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        ownerUserID: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        memberIdentifiers: [String] = [],
        invitationCode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.meetTime = meetTime
        self.locationName = locationName
        self.locationAddress = locationAddress
        self.locationNote = locationNote
        self.locationDisplayName = locationDisplayName
        self.latitude = latitude
        self.longitude = longitude
        self.ownerUserID = ownerUserID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.memberIdentifiers = memberIdentifiers
        self.invitationCode = invitationCode
    }

    var destination: Location? {
        guard let latitude, let longitude else { return nil }
        return Location(latitude: latitude, longitude: longitude)
    }

    var tripCode: String {
        invitationCode ?? ""
    }

    var creatorOwnerIdentifier: String {
        ownerUserID
    }
}

//// connecting user -> location
//func location(for user: UserModel) -> LocationModel? {
//    trip.locations.first {
//        $0.userId == user.id
//    }
//}
//// then
//if let location = location(for: user) {
//    print(location.latitude)
//}

//// showing on the map
//ForEach(trip.users) { user in
//
//    if let location = trip.locations.first(where: { $0.userId == user.id }) {
//
//        Marker(
//            user.name,
//            coordinate: CLLocationCoordinate2D(
//                latitude: location.latitude,
//                longitude: location.longitude
//            )
//        )
//    }
//}
