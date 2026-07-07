//
//  SecondView.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 6/7/26.
//

import SwiftUI
import Lottie


struct SecondView: View {
    @State private var appeared = false
    @State private var shimmerX: CGFloat = -1



    var body: some View {
        ZStack {

            Image("LiveActivity")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 375)
                           .offset(y: 70)
                           .scaleEffect(appeared ? 1.0 : 0.1)
                           .onAppear {
                               withAnimation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(2.3)
                               ) {
                                   appeared = true
                               }
                           }
                           .offset(y: -420)
            LottieView {
                try await DotLottieFile.named("SecondView")
            }
            .animationSpeed(0.75)
            .looping()
            .resizable()
            .frame(width: 560, height: 560)
            .offset(y: -110)
            
            
            VStack {
                VStack{

                    Spacer ()
                    
                    VStack{
                        HStack {
                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                            Rectangle ()
                                .fill(Color.cyan.opacity(1))
                                .frame(width: 30, height: 8)
                                .cornerRadius(12)
                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                        Text("The journey, at a glance.")
                            .font(.title)
                            .fontWidth(.expanded)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex:"343434"))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                        Text ("Live updates keep everyone's remaining distance just a glance away - right from the Lock Screen and Dynamic Island.")
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                            .opacity(0.5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                }
                Spacer()
                Button(action: {}) {
                    Text("How can I do that?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22.5)
                        .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 2)
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
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .padding(1)
        .ignoresSafeArea()
        
    }
}

#Preview {
    SecondView()
}
