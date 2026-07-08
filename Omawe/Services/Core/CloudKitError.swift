//
//  CloudKitError.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import Foundation

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case accountUnavailable
    case permissionDenied
    case recordNotFound
    case invalidRecord
    case invalidInvitation
    case networkUnavailable
    case conflict
    case operationFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to your iCloud account."
        case .accountUnavailable:
            return "Your iCloud account is currently unavailable."
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .recordNotFound:
            return "The requested data could not be found."
        case .invalidRecord:
            return "The CloudKit record is invalid."
        case .invalidInvitation:
            return "The invitation is invalid or has expired."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .conflict:
            return "This data has changed. Please refresh and try again."
        case .operationFailed:
            return "The CloudKit operation failed. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
