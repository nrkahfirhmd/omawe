//
//  OmaweApp.swift
//  Omawe
//
//  Created by Gleenryan on 29/06/26.
//

import SwiftUI
import SwiftData

@main
struct OmaweApp: App {
    @UIApplicationDelegateAdaptor(OmaweAppDelegate.self) private var appDelegate

    // LOC-4 decision: `LocationUpdate` is local-only (no CloudKit mirroring) —
    // LOC-1's manual CKRecord save is the sync transport, this model is
    // purely an on-disk offline write queue for it. `UserProfile` keeps
    // SwiftData's automatic CloudKit mirroring since nothing about it
    // requires the trip-scoped custom zone that ruled that out for location.
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationUpdate.self,
            UserProfile.self
        ])

        let localOnlyConfiguration = ModelConfiguration(
            schema: Schema([LocationUpdate.self]),
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        let mirroredConfiguration = ModelConfiguration(
            schema: Schema([UserProfile.self]),
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.exboyfriends.omaweapp")
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [localOnlyConfiguration, mirroredConfiguration]
            )
        } catch {
            fatalError("Could not create SwiftData model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
