import CloudKit

// MARK: - Backend integration point
// Single choke point for the CloudKit backend — every `CloudKit*Service`
// threads through `.shared`. Swapping backends means replacing this plus
// the `*ServiceProtocol` conformances call sites already depend on.
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
        debugLog("Container:", container.containerIdentifier ?? "nil")
    }
}
