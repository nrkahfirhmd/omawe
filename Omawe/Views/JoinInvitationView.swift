import SwiftUI

struct JoinInvitationView: View {
    let trip: Trip
    let onJoinNow: () async throws -> Void
    let onDismiss: () -> Void
    
    @State private var hasJoined = false
    @State private var isJoining = false
    @State private var joinErrorMessage: String?
    
    private var displayTripName: String {
        trip.title.isEmpty ? "Trip Name" : trip.title
    }
    
    private var displayLocationName: String {
        trip.destination.isEmpty ? "No location selected" : trip.destination
    }
    
    var body: some View {
        ZStack {
            invitationStageBackground
            
            CustomDynamicIsland(
                color: .black,
                borderColor: LinearGradient(stops: [
                    .init(color: Color(hex: "03B9D6"), location: 0.0),
                    .init(color: Color(hex: "7AE8FF"), location: 0.51),
                    .init(color: Color(hex: "03B9D6"), location: 1.0),
                ], startPoint: UnitPoint.leading, endPoint: .trailing),
                fillColor: .black
            )
            .padding(.top, 8)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !hasJoined {
                    header
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                InvitationTicketContainer(isEditing: false) {
                    if hasJoined {
                        joinedTicketContent
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        previewTicketContent
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .frame(maxWidth: 430)
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.54, dampingFraction: 0.88), value: hasJoined)
                .ignoresSafeArea()
                
                Spacer(minLength: 20)
                bottomControls
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if let joinErrorMessage {
                VStack {
                    Spacer()
                    Text(joinErrorMessage)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding()
                        .background(.black.opacity(0.8), in: Capsule())
                        .padding(.bottom, 120)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
    
    private var invitationStageBackground: some View {
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
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: hasJoined)
    }
    
    private var header: some View {
        VStack(spacing: 7) {
            Image(systemName: "eyes")
                .font(.button())
                .foregroundStyle(.white.opacity(0.3))
            
            Text("Invitation\nfrom Bintang")
                .font(.button())
                .fontWidth(.expanded)
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private var previewTicketContent: some View {
        VStack(spacing: 0) {
            VStack {
                VStack {
                    Text(displayTripName)
                        .font(.title1().weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                    
                    Text("by @\(trip.ownerDisplayName ?? "Anonymous")")
                        .font(.caption1())
                        .foregroundStyle(Theme.primaryBox.opacity(0.72))
                        .padding(.bottom, 12)
                }
                .padding(.bottom, 48)
                
                VStack(spacing: 18) {
                    ticketDetail(
                        label: "Event Date",
                        value: trip.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                        isDark: false
                    )
                    
                    ticketDetail(
                        label: "Meet Time",
                        value: trip.startDate.formatted(date: .omitted, time: .shortened),
                        isDark: false
                    )
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            
            Spacer(minLength: 0)
            
            VStack {
                Text("Location")
                    .font(.headline())
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.bottom, 4)
                
                VStack(spacing: 4) {
                    Text(displayLocationName)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.bottom, 12)
                
                HStack {
                    Text("#Code")
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white.opacity(0.28))
                    
                    Spacer()
                    
                    Text(trip.invitationCode)
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }
    
    private var joinedTicketContent: some View {
        VStack(spacing: 0) {
            // Top White Area
            VStack {
                ZStack {
                    Circle()
                        .fill(Theme.secondary)
                        .frame(width: 120, height: 120)
                    
                    Image(.avatar) // Use actual user avatar if available
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 120, height: 120)
                }
                .padding(.top, 20)
            }
            .frame(height: 220) // approximate height of the top white area
            
            // Bottom Dark Area
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                
                Text("You have successfully joined")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(displayTripName)
                    .font(.largeTitle.weight(.bold))
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.bottom, 12)
                
                VStack(spacing: 16) {
                    ticketDetail(
                        label: "Event Date",
                        value: trip.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                        isDark: true
                    )
                    
                    ticketDetail(
                        label: "Meet Time",
                        value: trip.startDate.formatted(date: .omitted, time: .shortened),
                        isDark: true
                    )
                }
                .padding(.bottom, 16)
                
                VStack(spacing: 4) {
                    Text(displayLocationName)
                        .font(.title3().weight(.bold))
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.bottom, 12)
                
                HStack {
                    Text("#Code")
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Spacer()
                    
                    Text(trip.invitationCode)
                        .font(.button().width(.expanded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .top)
    }
    
    private func ticketDetail(label: String, value: String, isDark: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline())
                .foregroundStyle(isDark ? .white.opacity(0.6) : .black.opacity(0.46))
            
            Text(value)
                .font(.title3().weight(isDark ? .bold : .regular))
                .fontWidth(.expanded)
                .foregroundStyle(isDark ? .white : .black.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if hasJoined {
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "house.fill")
                            .font(.button())
                        
                        Text("Back to home")
                            .font(.button())
                            .fontWidth(.expanded)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .foregroundStyle(.white)
                    .overlay {
                        Capsule()
                            .stroke(Theme.secondary, lineWidth: 1.5)
                    }
                }
                .glassEffect(.clear)
            } else {
                HStack(spacing: 12) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline())
                            .padding(8)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Go back")
                    
                    Button {
                        joinTrip()
                    } label: {
                        HStack(spacing: 14) {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 15)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.button())
                            }
                            
                            Text(isJoining ? "Joining..." : "Join Now")
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(.white)
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    .disabled(isJoining)
                }
            }
        }
    }
    
    private func joinTrip() {
        guard !isJoining else { return }
        isJoining = true
        joinErrorMessage = nil
        
        Task {
            do {
                try await onJoinNow()
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        hasJoined = true
                    }
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    joinErrorMessage = error.localizedDescription
                }
            }
        }
    }
}
