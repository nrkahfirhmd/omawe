//
//  InvitationStageBackground.swift
//  Omawe
//
//  Created by Antigravity on 09/07/26.
//

import SwiftUI

struct InvitationStageBackground: View {
    var hasJoined: Bool = false
    var spotLight: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: hasJoined ? [.black, Theme.secondaryBox] : [.black, Theme.primaryBox],
                startPoint: .top,
                endPoint: .bottom
            )
            
            PlusPattern()
                .mask(
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            if spotLight {
                SpotlightShape()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(hasJoined ? 0.4 : 0.26), .white.opacity(0.02), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 14)
                    .padding(.horizontal, 76)
                    .offset(y: 64)
            }
            
            
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: hasJoined)
    }
}
