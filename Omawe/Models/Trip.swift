import SwiftUI
import CloudKit
import CoreLocation

struct Trip : Identifiable, Hashable {
    let id: CKRecord.ID?
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    let ownerID: CKRecord.ID
    var ownerDisplayName: String?
    var invitationCode: String
    var status: TripStatus = .notStarted
    /// Captured once at trip creation
    var destinationLatitude: Double?
    var destinationLongitude: Double?
    var locationAddress: String?
    var apartmentUnitFloor: String?
    var locationNickname: String?
    var createdAt: Date
    var updatedAt: Date

    var destinationCoordinate: CLLocationCoordinate2D? {
        guard let destinationLatitude, let destinationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
}

enum TripStatus: String, Codable {
    case notStarted
    case active
    case ended
}
