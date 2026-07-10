import CloudKit

final class CloudKitIdentityService {
    private let container = CloudKitContainer.shared.container
    
    func accountStatus() async throws -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    private static var cachedUserID: CKRecord.ID?
    
    func currentUserRecordID() async throws -> CKRecord.ID {
        if let cached = Self.cachedUserID {
            return cached
        }
        
        let status = try await accountStatus()
        
        guard status == .available else {
            switch status {
            case .noAccount:
                throw CloudKitError.notAuthenticated
            case .restricted, .couldNotDetermine, .temporarilyUnavailable:
                throw CloudKitError.accountUnavailable
            @unknown default:
                throw CloudKitError.operationFailed
            }
        }
        
        do {
            let userID = try await container.userRecordID()
            Self.cachedUserID = userID
            return userID
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
