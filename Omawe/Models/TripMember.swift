//
//  TripMember.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import Foundation
import SwiftData

@Model
final class TripMember {
    var id: UUID = UUID()
    var tripID: UUID = UUID()
    var userID: String = ""
    var role: String = "owner"
    var joinedAt: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        tripID: UUID,
        userID: String,
        role: String = "member",
        joinedAt: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.tripID = tripID
        self.userID = userID
        self.role = role
        self.joinedAt = joinedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
