import Foundation
import AuthenticationServices

private enum SessionKeys {
    static let userIdentifier = "apple_user_identifier"
    static let displayName = "apple_display_name"
    static let email = "apple_user_email"
}

/// Single source of truth for Apple Sign In session state, independent of
/// CloudKit's own iCloud identity (`CKCurrentUserDefaultName`). Only the
/// user identifier, display name, and email are persisted — the identity
/// token is short-lived and intentionally never stored.
@Observable
final class UserSession {
    static let shared = UserSession()

    private(set) var userIdentifier: String? {
        didSet { UserDefaults.standard.set(userIdentifier, forKey: SessionKeys.userIdentifier) }
    }

    /// Apple only sends this on the first sign-in for a given app+user pair, so it's cached here.
    private(set) var displayName: String? {
        didSet { UserDefaults.standard.set(displayName, forKey: SessionKeys.displayName) }
    }

    private(set) var email: String? {
        didSet { UserDefaults.standard.set(email, forKey: SessionKeys.email) }
    }

    var isSignedIn: Bool {
        userIdentifier != nil
    }

    private init() {
        self.userIdentifier = UserDefaults.standard.string(forKey: SessionKeys.userIdentifier)
        self.displayName = UserDefaults.standard.string(forKey: SessionKeys.displayName)
        self.email = UserDefaults.standard.string(forKey: SessionKeys.email)
    }

    func save(result: AppleSignInResult) {
        userIdentifier = result.userIdentifier

        // Apple omits name/email on repeat sign-ins — only overwrite when present.
        if let name = result.displayName {
            displayName = name
        }
        if let resultEmail = result.email {
            email = resultEmail
        }
    }

    /// Clears only the credential — display name/email survive since Apple
    /// won't resend them on re-authentication for the same app+user pair.
    func clearCredential() {
        userIdentifier = nil
        UserDefaults.standard.removeObject(forKey: SessionKeys.userIdentifier)
    }

    func clearAll() {
        userIdentifier = nil
        displayName = nil
        email = nil

        UserDefaults.standard.removeObject(forKey: SessionKeys.userIdentifier)
        UserDefaults.standard.removeObject(forKey: SessionKeys.displayName)
        UserDefaults.standard.removeObject(forKey: SessionKeys.email)
    }

    /// Re-checks the stored credential against Apple (revoked/transferred/etc).
    /// Only clears the credential on failure, never the cached name/email —
    /// see `clearCredential`.
    func validateSession() async -> Bool {
        guard let userIdentifier else { return false }

        let service = AppleSignInService()
        do {
            let state = try await service.getCredentialState(for: userIdentifier)
            switch state {
            case .authorized:
                return true
            case .revoked, .notFound, .transferred:
                clearCredential()
                return false
            @unknown default:
                clearCredential()
                return false
            }
        } catch {
            // Transient network failure — keep the session; re-validated next launch.
            debugLog("[UserSession] Failed to validate credential state: \(error.localizedDescription)")
            return true
        }
    }
}
