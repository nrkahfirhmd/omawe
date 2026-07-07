
//
//  OnBoardingView.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 6/7/26.
//

import SwiftUI
import Lottie



struct ThirdView: View {

    var body: some View {
        ZStack {
            
            SpotlightBeam()
                .offset(y: 50)
            
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

            
            LottieView {
                try await DotLottieFile.named("ThirdView")
            }
            .animationSpeed(0.75)
            .looping()
            .resizable()
            .frame(width: 700, height: 700)
            .offset(y: -20)
            
            VStack {
                VStack{
                   
                    
                    Spacer ()
                    
                    VStack{
                        HStack {

                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)

                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                            
                            Rectangle ()
                                .fill(Color.cyan.opacity(1))
                                .frame(width: 30, height: 8)
                                .cornerRadius(12)
                            
                        }
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
                Button(action: {HapticManager.shared.tickTickTick()}) {
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
