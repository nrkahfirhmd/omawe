//
//  UserProfile.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var userID: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        userID: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
