//
//  TripStatusDetailView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import SwiftUI
import SwiftData

struct TripStatusDetailView: View {
    let trips: [TripModel]
    let members: [TripMember]
    let userProfiles: [UserProfile]
    @Binding var selectedTripIndex: Int
    var onClose: () -> Void

    private var selectedIndex: Int {
        guard !trips.isEmpty else { return 0 }
        return min(max(selectedTripIndex, 0), trips.count - 1)
    }

    private var selectedTrip: TripModel? {
        guard !trips.isEmpty else { return nil }
        return trips[selectedIndex]
    }

    private var selectedTripSubtitle: String {
        guard let selectedTrip else { return "" }

        return [
            ownerDisplayName(for: selectedTrip),
            selectedTrip.startDate.formatted(.dateTime.day().month(.abbreviated).year()),
            selectedTrip.meetTime.formatted(date: .omitted, time: .shortened)
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: " • ")
    }

    var body: some View {
        Group {
            if let selectedTrip {
                DynamicBox(
                    theme: Theme.themeSecondary,
                    icon: "balloon.2",
                    title: selectedTrip.name.isEmpty ? "Untitled trip" : selectedTrip.name,
                    subtitle: selectedTripSubtitle,
                    helperText: trips.count > 1 ? "Swipe to see other trips" : "Swipe up to close",
                    footerTitle: "Trip is not starting yet"
                ) {
                    VStack(spacing: 0) {
                        TabView(selection: $selectedTripIndex) {
                            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                                TripStatusPageContentView(
                                    trip: trip,
                                    members: memberDisplays(for: trip),
                                    totalTripCount: trips.count,
                                    subtitle: [
                                        ownerDisplayName(for: trip),
                                        trip.startDate.formatted(.dateTime.day().month(.abbreviated).year()),
                                        trip.meetTime.formatted(date: .omitted, time: .shortened)
                                    ]
                                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                                    .joined(separator: " • ")
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 300)

                        if trips.count > 1 {
                            TripPageIndicator(totalPages: trips.count, currentPage: selectedIndex)
                                .padding(.top, 8)
                                .padding(.bottom, 18)
                        }
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard value.translation.height < -42 else { return }
                    withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
                        onClose()
                    }
                }
        )
    }

    private func memberDisplays(for trip: TripModel) -> [TripStatusMemberDisplay] {
        let matchedMembers = members
            .filter { $0.tripID == trip.id }
            .sorted { $0.joinedAt < $1.joinedAt }

        if !matchedMembers.isEmpty {
            return matchedMembers.map {
                TripStatusMemberDisplay(
                    userID: $0.userID,
                    role: $0.role
                )
            }
        }

        return trip.memberIdentifiers.map {
            TripStatusMemberDisplay(userID: $0, role: $0 == trip.ownerUserID ? "owner" : "member")
        }
    }

    private func ownerDisplayName(for trip: TripModel) -> String {
        guard !trip.ownerUserID.isEmpty else { return "Owner unavailable" }

        if userProfiles.contains(where: { $0.userID == trip.ownerUserID }) {
            return "Owner \(shortUserID(trip.ownerUserID))"
        }

        return "Owner \(shortUserID(trip.ownerUserID))"
    }

    private func shortUserID(_ userID: String) -> String {
        String(userID.suffix(6))
    }
}

private struct TripStatusMemberDisplay: Identifiable, Hashable {
    var id: String { userID }
    let userID: String
    let role: String
}

private struct TripStatusPageContentView: View {
    let trip: TripModel
    let members: [TripStatusMemberDisplay]
    let totalTripCount: Int
    let subtitle: String
    
    private var orbitPeople: [PeopleOrbitPerson] {
        members.map { member in
            PeopleOrbitPerson(
                id: member.userID,
                displayName: displayName(for: member)
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PeopleOrbit(people: orbitPeople)
                .padding(.bottom, 16)

            HStack(spacing: 4) {
                Image(systemName: "location.circle.fill")
                Text(trip.locationName.isEmpty ? "Location unavailable" : trip.locationName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.caption.bold())
            .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
            .padding(.bottom, 24)

            HStack(spacing: 12) {
                StartTripButton()

                NavigationLink {
                    TripDetailView(
                        trip: trip,
                        subtitle: subtitle,
                        members: members.map {
                            TripDetailMember(
                                id: $0.userID,
                                name: displayName(for: $0),
                                isOwner: $0.userID == trip.ownerUserID
                            )
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                } label: {
                    Image(systemName: "list.bullet.indent")
                        .font(.largeTitle)
                        .foregroundStyle(Color.primary)
                        .frame(width: 55, height: 55)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())
                .accessibilityLabel("Trip options")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, totalTripCount > 1 ? 0 : 18)
        }
    }

    private func displayName(for member: TripStatusMemberDisplay) -> String {
        if member.userID == trip.ownerUserID {
            return member.role == "owner" ? "Owner" : "Member"
        }

        return member.role == "owner" ? "Owner" : "Member"
    }
}

// MARK: - Preview
#Preview {
    let container: ModelContainer = {
        let schema = Schema([TripModel.self, TripMember.self, UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }()
    
    let mockTrip = TripModel(
        name: "Weekend Bali Trip",
        startDate: Date(),
        meetTime: Date(),
        locationName: "Canggu Beach",
        ownerUserID: "user_owner_id",
        memberIdentifiers: ["user_owner_id", "user_member_1", "user_member_2"]
    )
    
    let mockMembers = [
        TripMember(tripID: mockTrip.id, userID: "user_owner_id", role: "owner"),
        TripMember(tripID: mockTrip.id, userID: "user_member_1", role: "member"),
        TripMember(tripID: mockTrip.id, userID: "user_member_2", role: "member")
    ]
    
    let mockUserProfiles = [
        UserProfile(userID: "user_owner_id"),
        UserProfile(userID: "user_member_1"),
        UserProfile(userID: "user_member_2")
    ]
    
    return TripStatusDetailView(
        trips: [mockTrip],
        members: mockMembers,
        userProfiles: mockUserProfiles,
        selectedTripIndex: .constant(0),
        onClose: {}
    )
    .modelContainer(container)
}
