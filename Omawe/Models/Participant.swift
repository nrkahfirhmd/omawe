//
//  Participant.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import SwiftUI
import CloudKit

struct Participant : Identifiable, Hashable {
    let id: CKRecord.ID?
    let tripID: CKRecord.ID
    let userID: CKRecord.ID
    var displayName: String?
    var role: ParticipantRole
    var joinedAt: Date
}

enum ParticipantRole : String {
    case owner
    case member
}
