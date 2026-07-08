//
//  OnboardingFlow.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 7/7/26.
//

import SwiftUI

struct OnboardingFlow: View {
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    /// The authentication view model shared with `ThirdView`.
    /// Created here so it survives page transitions and can access `finishOnboarding()`.
    @State private var authViewModel = AuthenticationViewModel()

    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                FirstView(onNext: { goTo(1) })
            case 1:
                SecondView(onNext: { goTo(2) })
            case 2:
                PermissionView(onNext: { goTo(3) })
            default:
                ThirdView(
                    onFinish: { finishOnboarding() },
                    viewModel: authViewModel
                )
            }
        }
        .background {
            if currentPage >= 1 {
                Image("DarkBlueBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            // Wire the VM's success callback to finishOnboarding().
            // When Apple Sign In succeeds, the VM saves the session and then
            // calls this closure, which sets hasCompletedOnboarding = true.
            // ContentView reacts to that @AppStorage change and navigates to HomeView.
            authViewModel.onSignInCompleted = {
                finishOnboarding()
            }
        }
    }

    private func goTo(_ page: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = page
        }
    }

    /// Marks onboarding as completed.
    /// Called by the AuthenticationViewModel after a successful Apple Sign In.
    /// This triggers ContentView to swap from OnboardingFlow to HomeView.
    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingFlow()
}
