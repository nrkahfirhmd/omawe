//
//  AppleSignInService.swift
//  Omawe
//
//  Created on 7/7/26.
//

import AuthenticationServices
import Foundation

// MARK: - Apple Sign In Result

/// Holds the data returned by a successful Apple Sign In.
/// The identity token is included for immediate use (e.g. server validation)
/// but should NOT be persisted — Apple issues short-lived tokens.
struct AppleSignInResult {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String?

    /// A formatted display name derived from the name components Apple provides.
    /// Apple only sends the full name on the FIRST sign-in; subsequent sign-ins
    /// return nil, so callers must cache this value.
    var displayName: String? {
        guard let fullName else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let formatted = formatter.string(from: fullName)
        return formatted.isEmpty ? nil : formatted
    }
}

// MARK: - Apple Sign In Error

/// Describes all failure modes for the Apple Sign In flow.
/// Each case maps to a user-friendly message for display in alerts.
enum AppleSignInError: LocalizedError {
    case cancelled
    case invalidCredential
    case invalidResponse
    case tokenDecodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled."
        case .invalidCredential:
            return "Invalid credentials. Please try again."
        case .invalidResponse:
            return "Received an invalid response from Apple. Please try again."
        case .tokenDecodingFailed:
            return "Failed to process authentication token. Please try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Apple Sign In Service

/// Encapsulates the complete Sign in with Apple flow.
///
/// This service bridges `ASAuthorizationController` (a UIKit/delegate-based API)
/// to Swift's modern `async/await` concurrency model using `withCheckedThrowingContinuation`.
///
/// Usage:
/// ```swift
/// let service = AppleSignInService()
/// let result = try await service.signIn()
/// ```
final class AppleSignInService: NSObject {

    // MARK: - Private State

    /// The continuation that bridges the delegate callbacks to async/await.
    /// Set when `signIn()` is called; fulfilled when the delegate fires.
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    // MARK: - Public API

    /// Presents the Sign in with Apple sheet and returns the authentication result.
    ///
    /// - This method requests `.fullName` and `.email` scopes.
    /// - Apple only provides name/email on the FIRST sign-in for a given app+user pair.
    /// - The returned `identityToken` is ephemeral and should NOT be persisted.
    ///
    /// - Returns: An `AppleSignInResult` containing the user's identifier and optional profile data.
    /// - Throws: `AppleSignInError` describing what went wrong.
    @MainActor
    func signIn() async throws -> AppleSignInResult {
        // Build the Apple ID authorization request with the scopes we need.
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        // Create the controller that manages the sign-in sheet presentation.
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        // Bridge the delegate-based API to async/await.
        // The continuation is captured and later resumed in the delegate methods.
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    /// Checks whether an existing Apple ID credential is still valid.
    ///
    /// Call this on app launch to detect if the user has:
    /// - Revoked the app's access in Settings → Apple ID → Sign-In & Security
    /// - Signed out of their Apple ID entirely
    ///
    /// - Parameter userIdentifier: The stable Apple user ID stored from a previous sign-in.
    /// - Returns: The current credential state (`.authorized`, `.revoked`, `.notFound`, etc.)
    func getCredentialState(for userIdentifier: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        return try await provider.credentialState(forUserID: userIdentifier)
    }
}

// MARK: - ASAuthorizationControllerDelegate

/// Handles the success/failure callbacks from the Apple Sign In sheet.
/// These delegate methods resume the `continuation` captured in `signIn()`.
extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        // We only requested Apple ID credentials, so we expect this specific type.
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.invalidResponse)
            continuation = nil
            return
        }

        // Decode the identity token from raw Data to a UTF-8 String.
        // This token is a signed JWT that can be validated server-side if needed.
        var tokenString: String?
        if let tokenData = credential.identityToken {
            tokenString = String(data: tokenData, encoding: .utf8)
            if tokenString == nil {
                continuation?.resume(throwing: AppleSignInError.tokenDecodingFailed)
                continuation = nil
                return
            }
        }

        let result = AppleSignInResult(
            userIdentifier: credential.user,
            email: credential.email,
            fullName: credential.fullName,
            identityToken: tokenString
        )

        continuation?.resume(returning: result)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Map ASAuthorizationError codes to our domain-specific error type.
        let mappedError: AppleSignInError
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                mappedError = .cancelled
            case .invalidResponse:
                mappedError = .invalidResponse
            case .notHandled, .failed:
                mappedError = .invalidCredential
            case .notInteractive:
                mappedError = .invalidCredential
            @unknown default:
                mappedError = .unknown(error)
            }
        } else {
            mappedError = .unknown(error)
        }

        continuation?.resume(throwing: mappedError)
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

/// Provides the window anchor for the Apple Sign In sheet.
/// In SwiftUI apps, we grab the key window from the first connected scene.
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Find the key window from the active window scene.
        // This is the standard approach for SwiftUI apps that don't have
        // a traditional UIWindow reference.
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            // Fallback: return any available window. This should never happen
            // in practice since the app must have at least one window scene.
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first ?? ASPresentationAnchor()
        }
        return window
    }
}
