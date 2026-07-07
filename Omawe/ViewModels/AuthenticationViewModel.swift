//
//  AuthenticationViewModel.swift
//  Omawe
//
//  Created on 7/7/26.
//

import Foundation

// MARK: - AuthenticationViewModel

/// ViewModel for the Sign in with Apple flow on the onboarding screen.
///
/// This class follows MVVM by keeping all authentication business logic
/// out of `ThirdView`. The view only binds to observable properties
/// (`isLoading`, `showError`, `errorMessage`) and calls `signInWithApple()`.
///
/// **Flow:**
/// 1. User taps "Continue with Apple" button in `ThirdView`.
/// 2. `ThirdView` calls `signInWithApple()` via a `Task`.
/// 3. This VM delegates to `AppleSignInService` to present the Apple sign-in sheet.
/// 4. On success: saves session via `UserSession`, then calls `onSignInCompleted()`.
/// 5. On failure: sets `errorMessage` and `showError` to trigger an alert in the view.
///
/// **Navigation:**
/// The `onSignInCompleted` closure is provided by `OnboardingFlow` and sets
/// `hasCompletedOnboarding = true`, which causes `ContentView` to swap to `HomeView`.
@Observable
final class AuthenticationViewModel {

    // MARK: - Dependencies

    /// The service that handles the Apple Sign In sheet and credential checks.
    private let appleSignInService = AppleSignInService()

    /// The session manager that persists user data to UserDefaults.
    private let session = UserSession.shared

    /// Closure called when sign-in completes successfully.
    /// This is set by `OnboardingFlow` and triggers the `hasCompletedOnboarding` flag.
    var onSignInCompleted: (() -> Void)?

    // MARK: - View State

    /// Whether an authentication request is currently in progress.
    /// When `true`, `ThirdView` shows a loading overlay on the button.
    var isLoading = false

    /// The error message to display in an alert.
    /// Set when authentication fails for any reason other than user cancellation.
    var errorMessage: String?

    /// Controls the presentation of the error alert in `ThirdView`.
    /// Automatically set to `true` when `errorMessage` is populated.
    var showError = false

    // MARK: - Actions

    /// Initiates the Sign in with Apple flow.
    ///
    /// This is the single entry point called by `ThirdView`'s button action.
    /// The method is `@MainActor` because it updates UI state (`isLoading`, etc.)
    /// and the underlying `ASAuthorizationController` must be presented on the main thread.
    ///
    /// **Success path:**
    /// 1. `AppleSignInService.signIn()` returns an `AppleSignInResult`.
    /// 2. `UserSession.save(result:)` persists the user identifier, name, and email.
    /// 3. `onSignInCompleted()` is called, setting `hasCompletedOnboarding = true`.
    /// 4. `ContentView` reacts to the `@AppStorage` change and navigates to `HomeView`.
    ///
    /// **Failure path:**
    /// - If the user cancels the sheet, we silently return (no error shown).
    /// - For all other errors, we show a user-friendly alert via `errorMessage`.
    @MainActor
    func signInWithApple() async {
        // Prevent multiple simultaneous sign-in attempts.
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            // Step 1: Present the Apple Sign In sheet and wait for the result.
            // This is where the user sees the Face ID / Touch ID / password prompt.
            let result = try await appleSignInService.signIn()

            // Step 2: Persist the session data (identifier, name, email).
            // The identity token is NOT saved — see UserSession for rationale.
            session.save(result: result)

            // Step 3: Trigger navigation to HomeView.
            // This calls back to OnboardingFlow.finishOnboarding(),
            // which sets hasCompletedOnboarding = true in @AppStorage.
            onSignInCompleted?()

        } catch let error as AppleSignInError {
            // Handle the mapped error from AppleSignInService.
            switch error {
            case .cancelled:
                // User dismissed the sign-in sheet — do nothing.
                // This is expected behavior, not an error condition.
                break
            default:
                // Show a user-friendly error message in an alert.
                errorMessage = error.errorDescription
                showError = true
            }
        } catch {
            // Catch-all for unexpected errors not mapped to AppleSignInError.
            errorMessage = "An unexpected error occurred. Please try again."
            showError = true
        }

        isLoading = false
    }
}
