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

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationUpdate.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.exboyfriends.omaweapp")
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
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
