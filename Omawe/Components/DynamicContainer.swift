//
//  DynamicContainer.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

struct DynamicContainer<Content: View>: View {
    private let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomStatusBar()
                .padding(.top)
            content
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(.black)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 54,
                style: .continuous
            )
        )
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        .padding(.top, 10)
        .padding(.horizontal, 10)
    }
}

#Preview {
    DynamicContainer {
        VStack(alignment: .leading, spacing: 14) {
            Text("Heading to Bandung")
                .font(.headline)

            HStack {
                Label("12 mins", systemImage: "clock")
                Spacer()
                Label("4.2 km", systemImage: "location.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))

            Button("View Trip") {
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
