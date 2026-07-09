import SwiftUI
import CloudKit

struct JoinInvitationView: View {
    let trip: Trip
    let onJoinNow: () async throws -> Void
    let onDismiss: () -> Void
    
    @State private var hasJoined = false
    @State private var isJoining = false
    @State private var joinErrorMessage: String?
    @State private var participants: [Participant]
    
    init(
        trip: Trip,
        participants: [Participant] = [],
        onJoinNow: @escaping () async throws -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.trip = trip
        self._participants = State(initialValue: participants)
        self.onJoinNow = onJoinNow
        self.onDismiss = onDismiss
    }
    
    private var displayTripName: String {
        trip.title.isEmpty ? "Trip Name" : trip.title
    }
    
    private var displayLocationName: String {
        trip.destination.isEmpty ? "No location selected" : trip.destination
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                InvitationStageBackground(hasJoined: hasJoined)
                
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
                    
                    header
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    
                    InvitationTicketContainer(isEditing: false, isJoined: hasJoined) {
                        if hasJoined {
                            joinedTicketContent
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            PreviewTicketContent(trip: trip, participants: participants)
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
            .task {
                if let tripID = trip.id {
                    do {
                        let fetched = try await CloudKitParticipantService().fetchParticipants(for: tripID)
                        await MainActor.run {
                            self.participants = fetched
                        }
                    } catch {
                        print("Failed to fetch participants: \(error)")
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 7) {
            Image(systemName: "eyes")
                .font(.button())
                .foregroundStyle(.white.opacity(0.3))
            
            Text("Invitation\nfrom \(trip.ownerDisplayName ?? "Anonymous")")
                .font(.button())
                .fontWidth(.expanded)
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private var joinedTicketContent: some View {
        
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle())
                Text("You have successfully joined")
                    .font(.callout())
                    .foregroundStyle(.white.opacity(0.46))
            }
            
            
            Text(displayTripName)
                .font(.title1().weight(.semibold))
                .fontWidth(.expanded)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.bottom, 4)
            
            
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
            
            VStack(spacing: 4) {
                Text(displayLocationName)
                    .font(.title3())
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let locationAddress = trip.locationAddress, !locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(locationAddress)
                        .font(.caption2())
                        .foregroundStyle(.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .lineLimit(3)
                }
            }
            
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
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }
    
    private func ticketDetail(label: String, value: String, isDark: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline())
                .foregroundStyle(isDark ? .white.opacity(0.46) : .black.opacity(0.46))
            
            Text(value)
                .font(.title3().weight(.semibold))
                .fontWidth(.expanded)
                .foregroundStyle(isDark ? .white.opacity(0.9) : .black.opacity(0.9))
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
                    joinErrorMessage = ErrorHelper.simplify(error)
                }
            }
        }
    }
}



#Preview {
    JoinInvitationView(
        trip: Trip(
            id: CKRecord.ID(recordName: "dummy-trip"),
            title: "Ex-boyfriends Celebration",
            destination: "Toko Kopi Jaya, Kuta",
            startDate: .now,
            endDate: .now,
            ownerID: CKRecord.ID(recordName: "Bintang"),
            ownerDisplayName: "Bintang",
            invitationCode: "1A6B7K",
            status: .notStarted,
            locationAddress: "Jl. Dewi Sri No. 99X, Legian, Kec. Kuta, Kabupaten Badung, Bali 80361",
            apartmentUnitFloor: "Luat's House",
            locationNickname: "Meeting Room",
            createdAt: .now,
            updatedAt: .now
        ),
        participants: [
            Participant(
                id: CKRecord.ID(recordName: "p1"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u1"),
                displayName: "Asep",
                role: .owner,
                joinedAt: .now,
                avatarImageData: UIImage(named: "avatar")?.pngData()
            ),
            Participant(
                id: CKRecord.ID(recordName: "p2"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u2"),
                displayName: "Budi",
                role: .member,
                joinedAt: .now,
                avatarImageData: UIImage(named: "avatar")?.pngData()
            ),
            Participant(
                id: CKRecord.ID(recordName: "p3"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u3"),
                displayName: "Cici",
                role: .member,
                joinedAt: .now,
                avatarImageData: UIImage(named: "avatar")?.pngData()
            ),
            Participant(
                id: CKRecord.ID(recordName: "p4"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u4"),
                displayName: "Deni",
                role: .member,
                joinedAt: .now
            ),
            Participant(
                id: CKRecord.ID(recordName: "p5"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u5"),
                displayName: "Eka",
                role: .member,
                joinedAt: .now
            ),
            Participant(
                id: CKRecord.ID(recordName: "p6"),
                tripID: CKRecord.ID(recordName: "dummy-trip"),
                userID: CKRecord.ID(recordName: "u6"),
                displayName: "Fani",
                role: .member,
                joinedAt: .now
            )
        ],
        onJoinNow: {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        },
        onDismiss: {},
    )
}
