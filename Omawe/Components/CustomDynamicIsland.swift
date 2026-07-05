//
//  CustomDynamicIsland.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 01/07/26.
//

import SwiftUI

struct CustomDynamicIsland: View {
    private let color: Color
    private let fillColor: Color
    private let borderColor: LinearGradient
    private let borderWidth: CGFloat
    private let width: CGFloat
    private let height: CGFloat
    private let isContentVisible: Bool

    init(
        color: Color = .black,
        borderColor: LinearGradient = LinearGradient(
            stops: [
                .init(color: Color(hex: "#B9F3FF"), location: 0.0),
                .init(color: Color(hex: "#53CBE4"), location: 0.51),
                .init(color: Color(hex: "#B9F3FF"), location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        ),
        fillColor: Color = .white,
        borderWidth: CGFloat = 0,
        width: CGFloat = 126,
        height: CGFloat = 37,
        isContentVisible: Bool = false
    ) {
        self.color = color
        self.borderColor = borderColor
        self.fillColor = fillColor
        self.borderWidth = borderWidth
        self.width = width
        self.height = height
        self.isContentVisible = isContentVisible
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(fillColor)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(borderColor, lineWidth: max(borderWidth, 1))
                }
                .frame(width: width + 10, height: height + 10)

            Capsule(style: .continuous)
                .fill(color)
                .frame(width: width, height: height)
        }
        .opacity(isContentVisible ? 0 : 1)
        .allowsHitTesting(!isContentVisible)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(
            .spring(response: 0.72, dampingFraction: 0.88, blendDuration: 0.12),
            value: isContentVisible
        )
    }
}

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()

        CustomDynamicIsland(
            color: .black,
            borderWidth: 2,
            width: 126,
            height: 37,
            isContentVisible: true
        )
    }
}
