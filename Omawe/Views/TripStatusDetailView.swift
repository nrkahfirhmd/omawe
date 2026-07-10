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
    var currentUserID: CKRecord.ID? = nil
    var tripActionErrorMessage: String? = nil
    var onEndTrip: (Trip) -> Void = { _ in }
    var onLeaveTrip: (Trip) async -> Void = { _ in }
    var onRemoveParticipant: (Participant) -> Void = { _ in }
    var onDeleteTrip: (Trip) async -> Void = { _ in }
    var onUpdateTrip: (Trip, TripDraft) -> Void = { _, _ in }

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
                                    isOwner: isOwner(of: trip),
                                    currentUserID: currentUserID,
                                    tripActionErrorMessage: tripActionErrorMessage,
                                    onStartTrip: { onStartTrip(trip) },
                                    onEndTrip: { onEndTrip(trip) },
                                    onLeaveTrip: { await onLeaveTrip(trip) },
                                    onRemoveParticipant: onRemoveParticipant,
                                    onDeleteTrip: { await onDeleteTrip(trip) },
                                    onUpdateTrip: { draft in onUpdateTrip(trip, draft) }
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

    /// Matches `HomeViewModel.isOwner` — see its doc comment for why `role`, not `trip.ownerID`.
    private func isOwner(of trip: Trip) -> Bool {
        guard let currentUserID else { return false }
        return members.contains { $0.tripID == trip.id && $0.userID == currentUserID && $0.role == .owner }
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
                    displayName: member.displayName ?? "Unknown",
                    participant: member
                )
            )
        }

        if displays.isEmpty {
            displays.append(
                TripStatusMemberDisplay(
                    userID: trip.ownerID,
                    role: .owner,
                    displayName: ownerDisplayName(for: trip),
                    participant: nil
                )
            )
        }

        return displays.sorted { lhs, rhs in
            if lhs.role == rhs.role { return lhs.displayName < rhs.displayName }
            return lhs.role == .owner
        }
    }

    private func ownerDisplayName(for trip: Trip) -> String {
        return trip.ownerDisplayName ?? "Owner unavailable"
    }

    private func displayName(for userID: CKRecord.ID, role: ParticipantRole, trip: Trip) -> String {
        if role == .owner, let name = trip.ownerDisplayName, !name.isEmpty {
            return name
        }
        
        if let participant = members.first(where: { $0.tripID == trip.id && $0.userID == userID }),
           let name = participant.displayName, !name.isEmpty {
            return name
        }
        
        return "Unknown"
    }
}

private struct TripStatusMemberDisplay: Identifiable, Hashable {
    var id: String { userID.recordName }
    let userID: CKRecord.ID
    let role: ParticipantRole
    let displayName: String
    let participant: Participant?
}

private struct TripStatusPageContentView: View {
    let trip: Trip
    let members: [TripStatusMemberDisplay]
    let totalTripCount: Int
    var isStartingTrip: Bool = false
    var isOwner: Bool = false
    var currentUserID: CKRecord.ID? = nil
    var tripActionErrorMessage: String? = nil
    var onStartTrip: () -> Void = {}
    var onEndTrip: () -> Void = {}
    var onLeaveTrip: () async -> Void = {}
    var onRemoveParticipant: (Participant) -> Void = { _ in }
    var onDeleteTrip: () async -> Void = {}
    var onUpdateTrip: (TripDraft) -> Void = { _ in }

    private var orbitPeople: [PeopleOrbitPerson] {
        members.map { member in
            PeopleOrbitPerson(
                id: member.userID.recordName,
                displayName: displayName(for: member),
                avatarImageData: member.participant?.avatarImageData
            )
        }
    }

    private var detailMembers: [TripDetailMember] {
        members.map { member in
            TripDetailMember(
                name: member.displayName,
                avatarData: member.participant?.avatarImageData
            )
        }
    }

    private var tripData: TripData {
        let owner = trip.ownerDisplayName ?? "Owner unavailable"
        let dateStr = trip.startDate.formatted(.dateTime.day().month(.abbreviated).year())
        let timeStr = trip.endDate.formatted(date: .omitted, time: .shortened)
        let subtitle = "by @\(owner) • \(dateStr) • \(timeStr)"
        
        return TripData(
            theme: Theme.themeSecondary,
            icon: "balloon.2",
            title: trip.title.isEmpty ? "Untitled trip" : trip.title,
            subtitle: subtitle,
            people: members.count,
            location: trip.destination.isEmpty ? "Location unavailable" : trip.destination,
            footerTitle: "Trip detail"
        )
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
            .padding(.bottom, 24)

            tripCodeView
                .padding(.bottom, 24)

            if let tripActionErrorMessage {
                Text(tripActionErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }

            HStack(spacing: 12) {
                if trip.status == .notStarted {
                    if isOwner {
                        StartTripButton(isDisabled: isStartingTrip, action: onStartTrip)
                    } else {
                        Text("Waiting to start...")
                            .font(.subheadline.weight(.semibold))
                            .fontWidth(.expanded)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22.5)
                            .background(.white.opacity(0.12), in: Capsule())
                    }
                } else if trip.status == .active {
                    if isOwner {
                        Button(role: .destructive, action: onEndTrip) {
                            Text("End Trip")
                                .font(.headline.weight(.semibold))
                                .fontWidth(.expanded)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .tint(.red)
                        .buttonStyle(.glassProminent)
                        .disabled(isStartingTrip)
                    } else {
                        Button(role: .destructive) {
                            Task {
                                await onLeaveTrip()
                            }
                        } label: {
                            Text("Leave trip")
                                .font(.headline.weight(.semibold))
                                .fontWidth(.expanded)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .tint(.red)
                        .buttonStyle(.glassProminent)
                        .disabled(isStartingTrip)
                    }
                } else {
                    Text("Trip has ended")
                        .font(.subheadline.weight(.semibold))
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22.5)
                        .background(.white.opacity(0.12), in: Capsule())
                }

                NavigationLink(destination: TripDetailView(
                    trip: tripData,
                    members: detailMembers,
                    isOwner: isOwner,
                    tripModel: trip,
                    onLeave: onLeaveTrip,
                    onRemoveMember: { member in
                        if let displayMember = members.first(where: { $0.displayName == member.name }),
                           let participant = displayMember.participant {
                            onRemoveParticipant(participant)
                        }
                    },
                    onDeleteTrip: onDeleteTrip,
                    onUpdateTrip: onUpdateTrip
                )) {
                    Image(systemName: "list.bullet.indent")
                        .font(.title1())
                        .foregroundStyle(Color.primary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())
                .accessibilityLabel("Trip options")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, totalTripCount > 1 ? 0 : 18)
            .task(id: trip.id) {
                while trip.status == .notStarted && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await TripStore.shared.loadTrips()
                }
            }
        }
    }

    private var tripCodeView: some View {
        Button {
            UIPasteboard.general.string = trip.invitationCode
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
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
        }
        .accessibilityLabel("Copy trip code \(trip.invitationCode)")
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

                    if isOwner, let participant = member.participant, member.userID != currentUserID {
                        Button {
                            onRemoveParticipant(participant)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
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

#Preview {
    @Previewable @State var selectedTripIndex = 0

    let trip1 = Trip(
        id: CKRecord.ID(recordName: "dummy-trip-1"),
        title: "Bali Surf Trip",
        destination: "Canggu Beach Club",
        startDate: .now,
        endDate: .now.addingTimeInterval(86400 * 3),
        ownerID: CKRecord.ID(recordName: "owner-1"),
        ownerDisplayName: "Bintang",
        invitationCode: "BALI99",
        status: .active,
        createdAt: .now,
        updatedAt: .now
    )

    let trip2 = Trip(
        id: CKRecord.ID(recordName: "dummy-trip-2"),
        title: "Kuta Beach Sunset",
        destination: "Kuta Beach, Bali",
        startDate: .now.addingTimeInterval(86400 * 4),
        endDate: .now.addingTimeInterval(86400 * 5),
        ownerID: CKRecord.ID(recordName: "owner-1"),
        ownerDisplayName: "Bintang",
        invitationCode: "KUTA22",
        status: .active,
        createdAt: .now,
        updatedAt: .now
    )

    let trip3 = Trip(
        id: CKRecord.ID(recordName: "dummy-trip-3"),
        title: "Ubud Yoga Retreat",
        destination: "Ubud Yoga Barn",
        startDate: .now.addingTimeInterval(86400 * 6),
        endDate: .now.addingTimeInterval(86400 * 8),
        ownerID: CKRecord.ID(recordName: "owner-2"),
        ownerDisplayName: "Gleen",
        invitationCode: "UBUD55",
        status: .notStarted,
        createdAt: .now,
        updatedAt: .now
    )

    let members = [
        Participant(
            id: CKRecord.ID(recordName: "p1"),
            tripID: CKRecord.ID(recordName: "dummy-trip-1"),
            userID: CKRecord.ID(recordName: "owner-1"),
            displayName: "Bintang",
            role: .owner,
            joinedAt: .now
        ),
        Participant(
            id: CKRecord.ID(recordName: "p2"),
            tripID: CKRecord.ID(recordName: "dummy-trip-1"),
            userID: CKRecord.ID(recordName: "member-1"),
            displayName: "Gleen",
            role: .member,
            joinedAt: .now.addingTimeInterval(3600)
        ),
        Participant(
            id: CKRecord.ID(recordName: "p3"),
            tripID: CKRecord.ID(recordName: "dummy-trip-2"),
            userID: CKRecord.ID(recordName: "owner-1"),
            displayName: "Bintang",
            role: .owner,
            joinedAt: .now
        ),
        Participant(
            id: CKRecord.ID(recordName: "p4"),
            tripID: CKRecord.ID(recordName: "dummy-trip-2"),
            userID: CKRecord.ID(recordName: "member-2"),
            displayName: "Baeni",
            role: .member,
            joinedAt: .now.addingTimeInterval(1800)
        ),
        Participant(
            id: CKRecord.ID(recordName: "p5"),
            tripID: CKRecord.ID(recordName: "dummy-trip-3"),
            userID: CKRecord.ID(recordName: "owner-2"),
            displayName: "Gleen",
            role: .owner,
            joinedAt: .now
        ),
        Participant(
            id: CKRecord.ID(recordName: "p6"),
            tripID: CKRecord.ID(recordName: "dummy-trip-3"),
            userID: CKRecord.ID(recordName: "owner-1"),
            displayName: "Bintang",
            role: .member,
            joinedAt: .now.addingTimeInterval(3600)
        )
    ]

    NavigationStack {
        TripStatusDetailView(
            trips: [trip1, trip2, trip3],
            members: members,
            userProfiles: [],
            selectedTripIndex: $selectedTripIndex,
            onClose: {},
            currentUserID: CKRecord.ID(recordName: "owner-1")
        )
    }
}
