import SwiftUI
import Lottie
import CloudKit
import Combine

struct InvitationEnvelopeView: View {
    let trip: Trip
    let onJoinNow: () async throws -> Void
    let onDismiss: () -> Void
    @State private var isOpened = false
    @State private var showInvitationCard = false
    private let timer = Timer.publish(every: 0.865, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if !showInvitationCard {
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
                        ? .playing(.fromFrame(30, toFrame: 82, loopMode: .playOnce))
                        : .playing(.fromFrame(6, toFrame: 30, loopMode: .loop))
                    )
                    .resizable()
                    .frame(width: 700, height: 700)
                    .onTapGesture {
                        isOpened = true
                        HapticManager.shared.envelopeOpen()
                        
                        // Triggers the transition faster (after 2.0 seconds) for a snappier user experience.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            HapticManager.shared.success()
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                showInvitationCard = true
                            }
                        }
                    }
                }
                .transition(.opacity)
            } else {
                JoinInvitationView(
                    trip: trip,
                    onJoinNow: onJoinNow,
                    onDismiss: onDismiss
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.1)
                            .combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            guard !isOpened else { return }
            HapticManager.shared.envelopeJiggle()
        }
    }
}


#Preview {
    InvitationEnvelopeView(
        trip: Trip(
        id: nil,
        title: "Kuta Sunset Surf and Chill",
        destination: "Toko Kopi Jaya, Kuta",
        startDate: Calendar.current.date(
            from: DateComponents(year: 2026, month: 6, day: 30)
        ) ?? .now,
        endDate: Calendar.current.date(
            from: DateComponents(year: 2026, month: 6, day: 30)
        ) ?? .now,
        ownerID: CKRecord.ID(recordName: "Bintang"),
        invitationCode: "1A6B7K",
        createdAt: .now,
        updatedAt: .now
        ),
                           onJoinNow: {},
                           onDismiss: {}
    )
}
