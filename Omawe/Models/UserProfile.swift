import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var userID: String = ""
    var displayName: String = ""
    var dateOfBirth: Date = Calendar.current.date(from: DateComponents(year: 2005, month: 3, day: 26)) ?? .now
    var gender: String = ""
    @Attribute(.externalStorage) var avatarImageData: Data? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        userID: String,
        displayName: String = "",
        dateOfBirth: Date? = nil,
        gender: String = "",
        avatarImageData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        if let dob = dateOfBirth {
            self.dateOfBirth = dob
        }
        self.gender = gender
        self.avatarImageData = avatarImageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
