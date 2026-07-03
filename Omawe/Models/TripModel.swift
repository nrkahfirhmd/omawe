//
//  TripModel.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 30/06/26.
//

import Foundation

struct TripModel {
    let id = UUID()
    var name: String
    var date: Date
    var meetTime: Date
    var destination: Location
    var tripCode: String
    
    var users: [UserModel]
    
    var locations: [LocationModel]
    
    var tripCreator: UserModel
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
