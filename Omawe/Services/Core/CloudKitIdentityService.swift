//
//  CloudKitIdentityService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

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
    
    func currentUserRecordID() async throws -> CKRecord.ID {
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
            return try await container.userRecordID()
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
