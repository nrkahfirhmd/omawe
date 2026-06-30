//
//  LocationModel.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

struct LocationModel {
    let id = UUID()
    var tripCode: String
    var userId: UUID
    var location: Location
    var lastUpdated: Date
}
