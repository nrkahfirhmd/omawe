//
//  ErrorHelper.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 09/07/26.
//

import Foundation

struct ErrorHelper {
    static func simplify(_ error: Error) -> String {
        if let ckError = error as? CloudKitError {
            switch ckError {
            case .unknown(let innerError):
                return simplify(innerError)
            default:
                return ckError.errorDescription ?? "Operation failed. Please try again."
            }
        }
        
        let errorMsg = error.localizedDescription.lowercased()
        if errorMsg.contains("owner participant") || errorMsg.contains("owner") {
            return "You are the owner of this trip."
        } else if errorMsg.contains("network") || errorMsg.contains("connection") || errorMsg.contains("offline") {
            return "Please check your internet connection and try again."
        } else if errorMsg.contains("permission denied") || errorMsg.contains("not have permission") {
            return "You don't have permission to perform this action."
        } else if errorMsg.contains("not found") || errorMsg.contains("exist") {
            return "The requested information could not be found."
        }
        
        return "An unexpected error occurred. Please try again."
    }
}
