//
//  ProfileHelper.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 09/07/26.
//

import Foundation
import SwiftData

struct ProfileHelper {
    static func currentUserProfile(from userProfiles: [UserProfile]) -> UserProfile? {
        userProfiles.first { $0.userID == UserSession.shared.userIdentifier } ?? userProfiles.first
    }
    
    static func displayName(for profile: UserProfile?) -> String? {
        profile?.displayName.isEmpty == false ? profile!.displayName : UserSession.shared.displayName
    }
    
    static func initials(for displayName: String?) -> String? {
        displayName?.first.map(String.init)
    }
    
    static func firstName(from displayName: String?) -> String {
        displayName?
            .split(separator: " ")
            .first
            .map(String.init) ?? "there"
    }
}
