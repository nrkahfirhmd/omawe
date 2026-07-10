import CloudKit

struct TripInvite: Identifiable, Hashable {
    var id: CKRecord.ID?
    var code: String
    var shareURL: URL
    var createdAt: Date
}
