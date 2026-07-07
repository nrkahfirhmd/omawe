//
//  Trip.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import SwiftUI
import CloudKit

struct Trip : Identifiable, Hashable {
    let id: CKRecord.ID?
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    let ownerID: CKRecord.ID
    var invitationCode: String
    var createdAt: Date
    var updatedAt: Date
}
