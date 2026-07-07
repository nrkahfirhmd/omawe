//
//  ContentView.swift
//  Omawe
//
//  Created by Gleenryan on 29/06/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    /// Tracks whether the initial session validation has completed.
    /// While `true`, a loading indicator is shown to prevent flashing
    /// the wrong screen before we know if the session is still valid.
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                // MARK: - Session Validation Loading
                // Brief loading state while we check the Apple credential.
                // This prevents showing HomeView for a split second before
                // discovering the credential was revoked.
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
            // MARK: - App Launch Session Validation
            // On every app launch, verify that the stored Apple credential
            // is still authorized. This catches cases where the user revoked
            // the app's access in Settings → Apple ID → Sign-In & Security.
            await validateSessionOnLaunch()
        }
    }

    /// Validates the Apple Sign In session when the app launches.
    ///
    /// If no session exists (fresh install), we skip validation.
    /// If a session exists but the credential is revoked, we clear the session
    /// and reset `hasCompletedOnboarding` to force the user through onboarding again.
    private func validateSessionOnLaunch() async {
        let session = UserSession.shared

        if session.isSignedIn {
            let isValid = await session.validateSession()
            if !isValid {
                // Credential was revoked — reset onboarding so the user
                // must sign in again. This also clears stored user data.
                hasCompletedOnboarding = false
            }
        }

        // Mark validation as complete to show the actual content.
        isCheckingSession = false
    }
}

#Preview {
    ContentView()
}
