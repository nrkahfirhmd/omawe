//
//  UserSession.swift
//  Omawe
//
//  Created on 7/7/26.
//

import Foundation
import AuthenticationServices

// MARK: - UserDefaults Keys

/// Centralizes all UserDefaults keys used for session persistence.
/// Using an enum prevents typos and makes it easy to find all stored keys.
private enum SessionKeys {
    static let userIdentifier = "apple_user_identifier"
    static let displayName = "apple_display_name"
    static let email = "apple_user_email"
}

// MARK: - UserSession

/// Manages the authenticated user's session state.
///
/// This is an `@Observable` singleton that persists minimal user data
/// in `UserDefaults`. It acts as the single source of truth for whether
/// the user is currently signed in via Apple.
///
/// **What is stored:**
/// - Apple User Identifier (stable, opaque string from Apple)
/// - Display Name (only available on first sign-in)
/// - Email (only available on first sign-in)
///
/// **What is NOT stored:**
/// - Identity Token — Apple issues short-lived JWTs that should only be
///   validated server-side. Storing them is unnecessary and a security risk.
///
/// **Relationship to CloudKit:**
/// This session is an *additional* authentication layer. CloudKit continues
/// to use its own iCloud identity (`CKCurrentUserDefaultName`) for data
/// operations. The two identity systems are independent.
@Observable
final class UserSession {

    // MARK: - Singleton

    /// Shared instance used throughout the app.
    /// Using a singleton ensures consistent session state across all views.
    static let shared = UserSession()

    // MARK: - Published Properties

    /// The Apple-provided stable user identifier.
    /// This value persists across sign-ins and is the primary key for the session.
    private(set) var userIdentifier: String? {
        didSet { UserDefaults.standard.set(userIdentifier, forKey: SessionKeys.userIdentifier) }
    }

    /// The user's display name, derived from the name components Apple provides.
    /// Apple only sends this on the FIRST sign-in, so it's cached here.
    private(set) var displayName: String? {
        didSet { UserDefaults.standard.set(displayName, forKey: SessionKeys.displayName) }
    }

    /// The user's email address from Apple.
    /// Like displayName, Apple only provides this on the first sign-in.
    /// The user may also choose to use Apple's private relay email.
    private(set) var email: String? {
        didSet { UserDefaults.standard.set(email, forKey: SessionKeys.email) }
    }

    /// Whether the user has an active session.
    /// This is a computed property — no separate storage needed.
    /// A session is considered valid if we have a stored user identifier.
    var isSignedIn: Bool {
        userIdentifier != nil
    }

    // MARK: - Initialization

    /// Private init loads any previously saved session from UserDefaults.
    /// This ensures the session state is immediately available on app launch
    /// without requiring an async call.
    private init() {
        self.userIdentifier = UserDefaults.standard.string(forKey: SessionKeys.userIdentifier)
        self.displayName = UserDefaults.standard.string(forKey: SessionKeys.displayName)
        self.email = UserDefaults.standard.string(forKey: SessionKeys.email)
    }

    // MARK: - Session Management

    /// Persists a successful Apple Sign In result.
    ///
    /// Called immediately after `AppleSignInService.signIn()` returns successfully.
    /// Only the user identifier, display name, and email are stored.
    /// The identity token is intentionally discarded.
    ///
    /// - Parameter result: The authentication result from `AppleSignInService`.
    func save(result: AppleSignInResult) {
        userIdentifier = result.userIdentifier

        // Only overwrite name/email if Apple actually provided them.
        // On subsequent sign-ins, these fields come back as nil,
        // so we preserve the previously cached values.
        if let name = result.displayName {
            displayName = name
        }
        if let resultEmail = result.email {
            email = resultEmail
        }
    }

    /// Clears only the authentication credential (user identifier).
    ///
    /// **Preserves the display name and email** so they survive re-authentication.
    /// This is critical because Apple only sends the name/email on the FIRST
    /// sign-in for a given app+user pair. If we wipe them here, they're lost
    /// forever (unless the user revokes the app in Apple ID settings and re-signs-in).
    ///
    /// Used when:
    /// - Credential state returns `.revoked` or `.notFound`
    /// - The user needs to re-authenticate but we want to keep their profile data
    func clearCredential() {
        userIdentifier = nil
        UserDefaults.standard.removeObject(forKey: SessionKeys.userIdentifier)
    }

    /// Clears ALL session data, including the cached display name and email.
    ///
    /// Use this only when:
    /// - The user explicitly signs out and wants a clean slate
    /// - The app needs a complete reset
    func clearAll() {
        userIdentifier = nil
        displayName = nil
        email = nil

        // Explicitly remove keys from UserDefaults to ensure clean state.
        UserDefaults.standard.removeObject(forKey: SessionKeys.userIdentifier)
        UserDefaults.standard.removeObject(forKey: SessionKeys.displayName)
        UserDefaults.standard.removeObject(forKey: SessionKeys.email)
    }

    /// Validates the current session against Apple's servers.
    ///
    /// Checks whether the stored Apple ID credential is still authorized.
    /// This catches cases where the user has:
    /// - Revoked the app in Settings → Apple ID → Sign-In & Security
    /// - Signed out of their Apple ID entirely
    /// - Been removed from the Apple Developer team (enterprise apps)
    ///
    /// **Important:** On failure, this only clears the credential (user identifier),
    /// NOT the cached display name or email. This ensures the name survives
    /// re-authentication, since Apple only sends it on the first sign-in.
    ///
    /// - Returns: `true` if the session is valid, `false` if it should be cleared.
    func validateSession() async -> Bool {
        guard let userIdentifier else {
            // No stored session — nothing to validate.
            return false
        }

        let service = AppleSignInService()
        do {
            let state = try await service.getCredentialState(for: userIdentifier)
            switch state {
            case .authorized:
                // Credential is still valid — session remains active.
                return true
            case .revoked, .notFound:
                // Credential was revoked or not found.
                // Only clear the credential, NOT the cached name/email.
                // When the user re-signs-in, save() will restore the identifier
                // and the preserved name/email will still be available.
                clearCredential()
                return false
            case .transferred:
                // Account was transferred to a different team.
                clearCredential()
                return false
            @unknown default:
                // Unknown state — treat as invalid for safety.
                clearCredential()
                return false
            }
        } catch {
            // Network or other error — keep the session for now.
            // We don't want a transient network issue to sign the user out.
            // The credential will be re-validated on the next launch.
            debugLog("[UserSession] Failed to validate credential state: \(error.localizedDescription)")
            return true
        }
    }
}
