import AuthenticationServices
import Foundation

/// The identity token is included for immediate use (e.g. server validation)
/// but should NOT be persisted — Apple issues short-lived tokens.
struct AppleSignInResult {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String?

    /// Apple only sends the full name on the FIRST sign-in; subsequent sign-ins
    /// return nil, so callers must cache this value.
    var displayName: String? {
        guard let fullName else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let formatted = formatter.string(from: fullName)
        return formatted.isEmpty ? nil : formatted
    }
}

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

/// Bridges `ASAuthorizationController`'s delegate-based API to async/await
/// via `withCheckedThrowingContinuation`.
final class AppleSignInService: NSObject {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    @MainActor
    func signIn() async throws -> AppleSignInResult {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func getCredentialState(for userIdentifier: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        return try await provider.credentialState(forUserID: userIdentifier)
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.invalidResponse)
            continuation = nil
            return
        }

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

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first ?? ASPresentationAnchor()
        }
        return window
    }
}
