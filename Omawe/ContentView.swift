import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    /// Prevents flashing the wrong screen before we know if the session is still valid.
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            } else if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingFlow()
            }
        }
        .task {
            await validateSessionOnLaunch()
        }
    }

    /// Catches cases where the user revoked Apple ID access in Settings
    /// since the last launch — resets onboarding to force re-sign-in.
    private func validateSessionOnLaunch() async {
        let session = UserSession.shared

        if session.isSignedIn {
            let isValid = await session.validateSession()
            if !isValid {
                hasCompletedOnboarding = false
            }
        }

        isCheckingSession = false
    }
}

#Preview {
    ContentView()
}
