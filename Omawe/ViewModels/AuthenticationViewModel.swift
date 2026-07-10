import Foundation

/// Sign in with Apple flow for the onboarding screen. Keeps auth logic out
/// of `ThirdView`, which only binds to `isLoading`/`showError`/`errorMessage`
/// and calls `signInWithApple()`. `onSignInCompleted` is wired by
/// `OnboardingFlow` to flip `hasCompletedOnboarding`, which is what makes
/// `ContentView` swap to `HomeView`.
@Observable
final class AuthenticationViewModel {
    private let appleSignInService = AppleSignInService()
    private let session = UserSession.shared

    var onSignInCompleted: (() -> Void)?

    var isLoading = false
    var errorMessage: String?
    var showError = false

    @MainActor
    func signInWithApple() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let result = try await appleSignInService.signIn()
            session.save(result: result)
            onSignInCompleted?()
        } catch let error as AppleSignInError {
            switch error {
            case .cancelled:
                break
            default:
                errorMessage = error.errorDescription
                showError = true
            }
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            showError = true
        }

        isLoading = false
    }
}
