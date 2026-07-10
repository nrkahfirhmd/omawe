
    import SwiftUI
    import Lottie

    struct PressScaleStyle: ButtonStyle {
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8),
                           value: configuration.isPressed)
        }
    }

    struct FirstView: View {
        var onNext: () -> Void = {}


        var body: some View {
            ZStack {
                LottieView {
                    try await DotLottieFile.named("OneView")
                }
                .animationSpeed(0.75)
                .looping()
                .resizable() 
                .frame(width: 560, height: 560)
                .offset(y: -110)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        HapticManager.shared.tickTickTick()
                    }
                }
                VStack {
                    VStack{
                        Button {
                        } label: {
                            CustomDynamicIsland(
                                color: .cyan,
                                borderColor: LinearGradient(stops: [
                                    .init(color: Color(hex: "03B9D6"), location: 0.0),
                                    .init(color: Color(hex: "7AE8FF"), location: 0.51),
                                    .init(color: Color(hex: "03B9D6"), location: 1.0),
                                ], startPoint: .leading, endPoint: .trailing)
                            )
                            .fixedSize()
                        }
                        .buttonStyle(PressScaleStyle())
                        .padding(.top, 8)
                        
                        Spacer ()
                        
                        VStack{
                            Text("Never wonder who's “nearly” there.")
                                .font(.title)
                                .fontWidth(.expanded)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(hex:"343434"))
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 10)
                            Text ("See everyone's progress to the same destination, so meeting up feels effortless.")
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
                    Button(action: {
                        HapticManager.shared.tickTickTick()
                        onNext()
                        
                    }) {
                        Text("Let's get started")
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
        FirstView()
    }
