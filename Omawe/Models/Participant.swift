import SwiftUI
import CloudKit

struct Participant : Identifiable, Hashable {
    let id: CKRecord.ID?
    let tripID: CKRecord.ID
    let userID: CKRecord.ID
    var displayName: String?
    var role: ParticipantRole
    var joinedAt: Date
    var avatarImageData: Data?
}

enum ParticipantRole : String {
    case owner
    case member
}
