//
//  CloudKitIdentityService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import CloudKit
import Foundation

enum CloudKitIdentityError: LocalizedError {
    case notSignedIn
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Sign in to iCloud to create and sync trips."
        case .restricted:
            return "This iCloud account is restricted from using CloudKit."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Check your connection and try again."
        case .couldNotDetermine:
            return "We could not confirm your iCloud account status. Please try again."
        case .unknown:
            return "CloudKit identity is unavailable right now. Please try again."
        }
    }
}

struct CloudKitIdentityService {
    private let container: CKContainer

    nonisolated init(containerIdentifier: String = "iCloud.com.exboyfriends.omaweapp") {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    nonisolated func currentUserID() async throws -> String {
        do {
            let status = try await container.accountStatus()
            print("[CloudKit] account status: \(String(describing: status))")

            switch status {
            case .available:
                let recordID = try await container.userRecordID()
                print("[CloudKit] resolved user record ID: \(recordID.recordName)")
                return recordID.recordName
            case .noAccount:
                print("[CloudKit] account unavailable: no account")
                throw CloudKitIdentityError.notSignedIn
            case .restricted:
                print("[CloudKit] account unavailable: restricted")
                throw CloudKitIdentityError.restricted
            case .temporarilyUnavailable:
                print("[CloudKit] account unavailable: temporarily unavailable")
                throw CloudKitIdentityError.temporarilyUnavailable
            case .couldNotDetermine:
                print("[CloudKit] account unavailable: could not determine")
                throw CloudKitIdentityError.couldNotDetermine
            @unknown default:
                print("[CloudKit] account unavailable: unknown account status")
                throw CloudKitIdentityError.couldNotDetermine
            }
        } catch let error as CloudKitIdentityError {
            print("[CloudKit] identity error: \(error.localizedDescription)")
            throw error
        } catch let error as CKError {
            print("[CloudKit] CKError while resolving identity: \(error.localizedDescription)")
            switch error.code {
            case .notAuthenticated:
                throw CloudKitIdentityError.notSignedIn
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
                throw CloudKitIdentityError.temporarilyUnavailable
            default:
                throw CloudKitIdentityError.unknown(error)
            }
        } catch {
            print("[CloudKit] unexpected identity error: \(error.localizedDescription)")
            throw CloudKitIdentityError.unknown(error)
        }
    }
}
