//
//  TripStatusDetailView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import SwiftUI
import CloudKit

struct TripStatusDetailView: View {
    let trips: [Trip]
    let members: [Participant]
    let userProfiles: [UserProfile]
    @Binding var selectedTripIndex: Int
    var onClose: () -> Void
    var isStartingTrip: Bool = false
    var onStartTrip: (Trip) -> Void = { _ in }

    private var selectedIndex: Int {
        guard !trips.isEmpty else { return 0 }
        return min(max(selectedTripIndex, 0), trips.count - 1)
    }

    private var selectedTrip: Trip? {
        guard !trips.isEmpty else { return nil }
        return trips[selectedIndex]
    }

    private var selectedTripSubtitle: String {
        guard let selectedTrip else { return "" }

        return [
            ownerDisplayName(for: selectedTrip),
            selectedTrip.startDate.formatted(.dateTime.day().month(.abbreviated).year()),
            selectedTrip.endDate.formatted(date: .omitted, time: .shortened)
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
                    title: selectedTrip.title.isEmpty ? "Untitled trip" : selectedTrip.title,
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
                                    isStartingTrip: isStartingTrip,
                                    onStartTrip: { onStartTrip(trip) }
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 380)

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

    private func memberDisplays(for trip: Trip) -> [TripStatusMemberDisplay] {
        let matchedMembers = members
            .filter { $0.tripID == trip.id }
            .sorted { $0.joinedAt < $1.joinedAt }

        var displays: [TripStatusMemberDisplay] = []
        var seenUserIDs = Set<CKRecord.ID>()

        for member in matchedMembers {
            guard !member.userID.recordName.isEmpty else { continue }
            seenUserIDs.insert(member.userID)
            displays.append(
                TripStatusMemberDisplay(
                    userID: member.userID,
                    role: member.role,
                    displayName: displayName(for: member.userID, role: member.role, trip: trip)
                )
            )
        }

        if displays.isEmpty {
            displays.append(
                TripStatusMemberDisplay(
                    userID: trip.ownerID,
                    role: .owner,
                    displayName: displayName(for: trip.ownerID, role: .owner, trip: trip)
                )
            )
        }

        return displays.sorted { lhs, rhs in
            if lhs.role == rhs.role { return lhs.displayName < rhs.displayName }
            return lhs.role == .owner
        }
    }

    private func ownerDisplayName(for trip: Trip) -> String {
        guard !trip.ownerID.recordName.isEmpty else { return "Owner unavailable" }

        if userProfiles.contains(where: { $0.userID == trip.ownerID.recordName }) {
            return "Owner \(shortUserID(trip.ownerID))"
        }

        return "Owner \(shortUserID(trip.ownerID))"
    }

    private func shortUserID(_ userID: CKRecord.ID) -> String {
        String(userID.recordName.suffix(6))
    }

    private func displayName(for userID: CKRecord.ID, role: ParticipantRole, trip: Trip) -> String {
        let suffix = shortUserID(userID)
        if role == .owner || userID == trip.ownerID {
            return "Owner \(suffix)"
        }

        return "Member \(suffix)"
    }
}

private struct TripStatusMemberDisplay: Identifiable, Hashable {
    var id: String { userID.recordName }
    let userID: CKRecord.ID
    let role: ParticipantRole
    let displayName: String
}

private struct TripStatusPageContentView: View {
    let trip: Trip
    let members: [TripStatusMemberDisplay]
    let totalTripCount: Int
    var isStartingTrip: Bool = false
    var onStartTrip: () -> Void = {}

    private var orbitPeople: [PeopleOrbitPerson] {
        members.map { member in
            PeopleOrbitPerson(
                id: member.userID.recordName,
                displayName: displayName(for: member)
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PeopleOrbit(people: orbitPeople)
                .padding(.bottom, 12)

            HStack(spacing: 4) {
                Image(systemName: "location.circle.fill")
                Text(trip.destination.isEmpty ? "Location unavailable" : trip.destination)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.caption.bold())
            .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
            .padding(.bottom, 10)

            tripCodeView
                .padding(.bottom, 12)

//            memberListView
//                .padding(.bottom, 18)

            HStack(spacing: 12) {
                if trip.status == .notStarted {
                    StartTripButton(isDisabled: isStartingTrip, action: onStartTrip)
                } else {
                    Text(trip.status == .active ? "Trip is on the way" : "Trip has ended")
                        .font(.subheadline.weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22.5)
                        .background(.white.opacity(0.12), in: Capsule())
                }

                Button {
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

    private var tripCodeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "number")
                .font(.caption.bold())

            Text(trip.invitationCode.isEmpty ? "No code" : trip.invitationCode)
                .font(.headline.weight(.bold))
                .fontWidth(.expanded)
                .monospaced()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.1), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .accessibilityLabel("Trip code \(trip.invitationCode)")
    }

    private var memberListView: some View {
        VStack(spacing: 8) {
            ForEach(Array(members.prefix(4)), id: \.id) { member in
                HStack(spacing: 10) {
                    Text(initials(for: member.displayName))
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(.white, in: Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text(member.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(member.role == .owner ? "Owner" : "Member")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if members.count > 4 {
                Text("+\(members.count - 4) more")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
    }

    private func displayName(for member: TripStatusMemberDisplay) -> String {
        member.displayName
    }

    private func initials(for displayName: String) -> String {
        let initials = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()

        return initials.isEmpty ? "?" : initials.uppercased()
    }
}
