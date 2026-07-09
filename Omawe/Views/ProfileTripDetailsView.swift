//
//  ProfileTripDetailsView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI
import CloudKit

struct ProfileTripDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let trip: Trip
    @State private var participants: [Participant]
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteErrorAlert = false
    
    init(
        trip: Trip,
        participants: [Participant] = [],
    ) {
        self.trip = trip
        self._participants = State(initialValue: participants)
    }
    
    var body: some View {
        NavigationStack{
            
            ZStack {
                backgroundImage
                    .ignoresSafeArea()
                
                VStack {
                    tripDateCapsule
                        .padding(.top, 24)
                    
                    PreviewTicketContent(trip: trip, participants: participants, bottomRatio: 0.55)
                }
                
                if isDeleting {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Deleting...")
                        .tint(.white)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                }
            }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if trip.id != nil {
                            showDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .disabled(isDeleting)
                }
            }
            .confirmationDialog(
                "Delete Trip",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteTrip()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this trip? This action cannot be undone.")
            }
            .alert("Error Deleting Trip", isPresented: $showDeleteErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let deleteErrorMessage {
                    Text(deleteErrorMessage)
                }
            }
            .navigationTitle("Trip Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var tripDateCapsule: some View {
        Text(tripDateCapsuleText)
            .font(.subheadline)
            .foregroundStyle(tripDateCapsuleTextColor)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .background(tripDateCapsuleBackground)
            .clipShape(Capsule())
    }
    
    private var formattedTripDate: String {
        trip.startDate.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }
    
    private var locationNoteCapsule: some View {
        Text("No note provided.")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .frame(maxWidth: 250)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
    }
    
    // DATE CAPSULE LOGIC
    private var hasTripPassed: Bool {
        trip.startDate < Calendar.current.startOfDay(for: .now)
    }
    
    private var tripDateCapsuleText: String {
        if hasTripPassed {
            return "This trip took place on \(formattedTripDate)"
        } else {
            return "This trip is scheduled for \(formattedTripDate)"
        }
    }
    
    private var tripDateCapsuleBackground: Color {
        hasTripPassed
        ? .black.opacity(0.05)
        : .green
    }
    
    private var backgroundWaveColor: Color {
        hasTripPassed
        ? Theme.primaryBox
        : Theme.secondaryBox
    }
    
    private var tripDateCapsuleTextColor: Color {
        hasTripPassed
        ? .secondary
        : .white
    }
    // DATE CAPSULE LOGIC END
    
    // IMAGE CHANGE LOGIC
    private var backgroundImage: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image(.moire)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                
                ZStack {
                    LinearGradient(
                        colors: [
                            .black,
                            backgroundWaveColor,
                        ],
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
                }
                .clipShape(BottomWave())
                .frame(height: geo.size.height * 0.40)
            }
        }
    }
    
    private func deleteTrip() {
        guard let tripID = trip.id else { return }
        isDeleting = true
        deleteErrorMessage = nil
        
        Task {
            do {
                try await CloudKitTripService().deleteTrip(id: tripID)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = error.localizedDescription
                    showDeleteErrorAlert = true
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        ProfileTripDetailsView(
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
        )
    }
}
