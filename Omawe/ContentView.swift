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
    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView()
}
