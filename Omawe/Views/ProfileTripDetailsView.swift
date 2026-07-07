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
    var viewModel: HomeViewModel = HomeViewModel()

    @State private var currentUserID: CKRecord.ID?

    private var tripParticipants: [Participant] {
        viewModel.participants
            .filter { $0.tripID == trip.id }
            .sorted { $0.joinedAt < $1.joinedAt }
    }

    private var isOwner: Bool {
        guard let currentUserID else { return false }
        return viewModel.isOwner(of: trip, userID: currentUserID)
    }

    private func shortUserID(_ userID: CKRecord.ID) -> String {
        String(userID.recordName.suffix(6))
    }

    var body: some View {
        NavigationStack{
            ZStack {
            
                Image(.tripDetailsSheetBG)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    tripDateCapsule
                        .padding(.top, 40)
                    
                    Text(trip.title)
                        .font(.title1())
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    Text("by @\(trip.ownerID.recordName)")
                        .font(.caption1())
                        .padding(.top, 5)
                    
                    ParticipantAvatarsView(
                        avatars: Array(repeating: ImageResource.avatar, count: max(tripParticipants.count, 1))
                    )
                    .padding(.top, 5)

                    memberManagementSection
                        .padding(.top, 12)

                    if let errorMessage = viewModel.tripActionErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 6)
                    }

                    //Spacer()

                    Text("Event Date")
                        .font(.headline())
                        .padding(.top, 40)
                        .foregroundStyle(.gray)
                    Text(formattedTripDate)
                        .font(.title3())
                        .fontWidth(.expanded)
                        

                        //.padding(.top, 5)

                    Text("Location")
                        .font(.headline())
                        .padding(.top, 110)
                        .foregroundStyle(.gray)
                    Text(trip.destination)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 3)
                    Text("")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                        .multilineTextAlignment(.center)
                    
                    locationNoteCapsule
                        .padding(.top, 20)

                    HStack {
                        Text("#Code")
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)

                        Spacer()
                        Text(trip.invitationCode)
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    tripLifecycleActions
                        .padding(.top, 20)

                    Spacer()
                }
            }
        }
        .task {
            currentUserID = try? await viewModel.currentUserID()
            await viewModel.loadTrips()
        }
    }

    @ViewBuilder
    private var memberManagementSection: some View {
        VStack(spacing: 8) {
            ForEach(tripParticipants, id: \.id) { participant in
                HStack(spacing: 10) {
                    Text(participant.role == .owner ? "Owner" : "Member")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))

                    Text(shortUserID(participant.userID))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    Spacer()

                    if isOwner, participant.userID != currentUserID {
                        Button {
                            Task { await viewModel.removeParticipant(participant) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var tripLifecycleActions: some View {
        HStack(spacing: 12) {
            switch trip.status {
            case .notStarted:
                Button {
                    Task { await viewModel.startTrip(trip) }
                } label: {
                    Text("Start trip now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUpdatingTripStatus)
            case .active:
                if isOwner {
                    Button(role: .destructive) {
                        Task { await viewModel.endTrip(trip) }
                    } label: {
                        Text("End trip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isUpdatingTripStatus)
                } else {
                    Button(role: .destructive) {
                        Task { await viewModel.leaveTrip(trip) }
                    } label: {
                        Text("Leave trip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            case .ended:
                Text("Trip has ended")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var tripDateCapsule: some View {
        Text("The trip took place on \(formattedTripDate)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .background(.black.opacity(0.05))
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
    
    private var formattedMeetTime: String {
        trip.startDate.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
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
}

struct ParticipantAvatarsView: View {
    let avatars: [ImageResource]

    private let avatarSize: CGFloat = 38
    private let overlap: CGFloat = 12

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(avatars.prefix(3).enumerated()), id: \.offset) { _, avatar in
                Image(avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: avatarSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 2)
                    }
            }

            if avatars.count > 3 {
                Text("+\(avatars.count - 3)")
                    .font(.caption1())
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 15)
            }
        }
    }
}

struct TripParticipant: Identifiable {
    let id = UUID()
    let name: String
    let avatar: ImageResource
}



#Preview("Trip details") {
    NavigationStack {
        ProfileTripDetailsView(
            trip: Trip(
                id: CKRecord.ID(recordName: "dummy-trip"),
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
            )
        )
    }
}
