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

    /// Triggers ContentView to swap from OnboardingFlow to HomeView.
    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingFlow()
}
