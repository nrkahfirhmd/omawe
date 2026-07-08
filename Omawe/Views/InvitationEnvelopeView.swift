//
//  InvitationEnvelopeView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 08/07/26.
//

import SwiftUI
import Lottie

struct InvitationEnvelopeView: View {
    let trip: Trip
    let onJoinNow: () async throws -> Void
    let onDismiss: () -> Void
    @State private var isOpened = false
    @State private var showInvitationCard = false
    
    var body: some View {
        ZStack {
            
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: Theme.primaryBox, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#014E5C").opacity(0.1), location: 0.5),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                
            }
            .ignoresSafeArea()
            
            VStack {
                CustomDynamicIsland(
                    color: .cyan,
                    borderColor: LinearGradient(stops: [
                        .init(color: Color(hex: "03B9D6"), location: 0.0),
                        .init(color: Color(hex: "7AE8FF"), location: 0.51),
                        .init(color: Color(hex: "03B9D6"), location: 1.0),
                    ], startPoint: .leading, endPoint: .trailing)
                )
                .fixedSize()
                .padding(.top, 9)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 6) {
                
                Text("Tap the card")
                    .font(.title2.weight(.bold))
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                
                Text("to reveal your trip details!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
            }
            .padding(.top, 80)
            
            ZStack {
                Circle()
                    .fill(Theme.primary)
                    .blur(radius: 50)
                    .frame(width: 200, height: 200)
                    .opacity(0.5)
                
                PlusPattern()
                    .mask(
                        RadialGradient(
                            gradient: Gradient(colors: [.black, .clear]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
            }
            .offset(y: 20)
            
            LottieView {
                try await DotLottieFile.named("ThirdView")
            }
            .playbackMode(
                isOpened
                ? .playing(.fromFrame(30, toFrame: 193, loopMode: .playOnce))
                : .playing(.fromFrame(6, toFrame: 30, loopMode: .loop))
            )
            .resizable()
            .frame(width: 700, height: 700)
            .onTapGesture {
                isOpened = true
                
                // Animation takes ~5 seconds (60 to 193 at 30 fps is ~4.4s).
                // Let's trigger the transition when it ends.
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    showInvitationCard = true
                }
            }
        }
        .navigationDestination(isPresented: $showInvitationCard) {
            JoinInvitationView(
                trip: trip,
                onJoinNow: onJoinNow,
                onDismiss: onDismiss
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
}
