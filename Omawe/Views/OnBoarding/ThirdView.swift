
//
//  OnBoardingView.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 6/7/26.
//

import UIKit
import SwiftUI
import Lottie



struct ThirdView: View {
    @State private var phase = 0
    @State private var isHolding = false
    
    var body: some View {
        ZStack {
            LottieView {
                try await DotLottieFile.named("ThirdViewNew")
            }
            .animationSpeed(0.75)
            .playing(phase == 0
                ? .fromFrame(0, toFrame: 90, loopMode: .playOnce)
                : .fromFrame(40, toFrame: 90, loopMode: .loop))
            .animationDidFinish { _ in
                if phase == 0 { phase = 1 }
            }
            .resizable()
            .frame(width: 550, height: 550)
            .offset(y: -20)
            .brightness(-0.15)
            .saturation(1.2)
            .scaleEffect(isHolding ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHolding)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.3),
                        .init(color: .black, location: 0.6),
                        .init(color: .clear, location: 0.9),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .contentShape(Rectangle())                                   // để bắt chạm trên cả vùng
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding {
                            isHolding = true
                            HapticManager.shared.chargeStart()           // bắt đầu giữ -> tích năng lượng
                        }
                    }
                    .onEnded { _ in
                        isHolding = false
                        HapticManager.shared.boom()                      // thả -> bùm
                    }
            )
            .zIndex(1)
            
            
            SpotlightBeam()
                .offset(y: 50)
                .allowsHitTesting(false)
            
            VStack(spacing: 4) {
                Image(systemName: "eyes")
                    .foregroundStyle(Color.white.opacity(0.7))
                    .font(.title3)
                    .padding(.bottom, 6)
                Text("Let's make\nyour 1st trip")
                    .font(.title3)
                    .fontWidth(.expanded)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .offset(y: -300)
            .allowsHitTesting(false)

            

            VStack {
                VStack{
                   
                    
                    Spacer ()
                    
                    VStack{

                        Text("Welcome aboard.")
                            .font(.title)
                            .fontWidth(.expanded)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex:"ffffff"))
                            .frame(maxWidth: .infinity)
                            .shadow(color: .cyan.opacity(0.5), radius: 8, x: 0, y: 0)
                            .padding(.bottom, 10)
                        Text ("Your location is only shared during trips you choose to join.")
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.white)
                            .opacity(0.5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                }
                Spacer()
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)}) {
                    Text("   Continue with Apple")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22.5)
                        .shadow(color: .blue.opacity(0.8), radius: 6, x: 0, y: 2)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(stops: [
                                        .init(color: Color(hex: "03B9D6"), location: 0.0),
                                        .init(color: Color(hex: "7AE8FF"), location: 1),
                                    ], startPoint: UnitPoint.top, endPoint: .bottom)
                                )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(stops: [
                                        .init(color: Color(hex: "03B9D6"), location: 0.0),
                                        .init(color: Color(hex: "7AE8FF"), location: 1),
                                    ], startPoint: UnitPoint.trailing, endPoint: .leading),
                                    lineWidth: 1
                                )
                                .shadow(color: Color(red: 0.4, green: 0.85, blue: 0.9).opacity(0.6), radius: 8)
                        )
                        .clipShape(Capsule())
                }
                .shadow(color: .cyan.opacity(0.4), radius: 10, x: 0, y: 0)
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
            }
            .containerRelativeFrame(.horizontal) { width, _ in
                width * 1
            }

        }
        .background {
            Image("DarkBlueBackground")
                .scaledToFill()
                .ignoresSafeArea()
        }
        .padding(1)
        .ignoresSafeArea()
        
    }
}

struct SpotlightBeam: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let topWidth: CGFloat = 70      // bề rộng đỉnh chùm sáng
                let midX = w / 2
                path.move(to: CGPoint(x: midX - topWidth/2, y: 0))
                path.addLine(to: CGPoint(x: midX + topWidth/2, y: 0))
                path.addLine(to: CGPoint(x: w * 0.95, y: geo.size.height))  // loe rộng ở đáy
                path.addLine(to: CGPoint(x: w * 0.05, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),   // sáng ở đỉnh
                        Color.white.opacity(0.0)      // tắt dần xuống dưới
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: 30)   // làm mềm mép chùm sáng
        }
    }
}

#Preview {
    ThirdView()
}
