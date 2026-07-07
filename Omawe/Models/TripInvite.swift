//
//  TripInvite.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
//

import CloudKit

struct TripInvite: Identifiable, Hashable {
    var id: CKRecord.ID?
    var code: String
    var shareURL: URL
    var createdAt: Date
}
