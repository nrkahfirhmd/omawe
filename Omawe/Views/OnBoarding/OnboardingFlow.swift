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

    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                FirstView(onNext: { goTo(1) })
                    .transition(.opacity)

            case 1:
                SecondView(onNext: { goTo(2) })
                    .transition(.identity)

            default:
                ThirdView {
                    finishOnboarding()
                }
                .transition(.opacity)
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
    }

    private func goTo(_ page: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = page
        }
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingFlow()
}
