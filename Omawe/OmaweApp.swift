import SwiftUI
import SwiftData

@main
struct OmaweApp: App {
    @UIApplicationDelegateAdaptor(OmaweAppDelegate.self) private var appDelegate

    // LOC-4: `LocationUpdate` is local-only (LOC-1's manual CKRecord save is
    // the real sync transport); `UserProfile` keeps SwiftData's automatic
    // CloudKit mirroring since it has no trip-scoped zone requirement.
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocationUpdate.self,
            UserProfile.self
        ])

        let localOnlyConfiguration = ModelConfiguration(
            "LocationUpdateStore",
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
