//
//  CloudKitContainer.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

final class CloudKitContainer {
    static let shared = CloudKitContainer()
    let container: CKContainer
    let privateDatabase: CKDatabase
    let publicDatabase: CKDatabase
    let sharedDatabase: CKDatabase

    private init() {
        container = CKContainer(identifier: "iCloud.com.exboyfriends.omaweapp")
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        print("Container:", container.containerIdentifier ?? "nil")
    }
}
