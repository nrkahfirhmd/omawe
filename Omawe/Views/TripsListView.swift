import SwiftUI
import CloudKit

struct TripsListView: View {
    @State private var selectedSegment: TripListSegment = .totalTrips
    @State private var searchText = ""
    @State private var homeViewModel = HomeViewModel()
    @State private var currentUserID: CKRecord.ID?

    init(initialSegment: TripListSegment = .totalTrips) {
            _selectedSegment = State(initialValue: initialSegment)
        }
    
    private var trips: [Trip] { homeViewModel.trips }

    private var displayedTrips: [Trip] {
        let today = Calendar.current.startOfDay(for: .now)

        let segmentTrips: [Trip] = switch selectedSegment {
        case .totalTrips:
            trips
        case .nextTrips:
            trips.filter { $0.startDate >= today }
        }

        guard !searchText.isEmpty else { return segmentTrips }

        return segmentTrips.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// See HomeView's equivalent `activeTrip` for why the participant check matters.
    private var activeTrip: Trip? {
        guard let currentUserID else { return nil }
        let myTripIDs: Set<CKRecord.ID> = Set(
            homeViewModel.participants
                .filter { $0.userID == currentUserID }
                .map { $0.tripID }
        )
        return homeViewModel.trips.first { trip in
            guard trip.status == .active, let tripID = trip.id else { return false }
            return myTripIDs.contains(tripID)
        }
    }

    var body: some View {
        Group {
            if let activeTrip {
                OnTripView(
                    trip: activeTrip,
                    participantCount: max(
                        homeViewModel.participants.filter { $0.tripID == activeTrip.id }.count,
                        1
                    ),
                    participants: homeViewModel.participants.filter { $0.tripID == activeTrip.id },
                    participantStates: homeViewModel.allParticipantTripStates,
                    currentUserID: currentUserID,
                    etaMinutes: currentUserID.flatMap { homeViewModel.currentUserTripState(for: activeTrip, userID: $0)?.etaMinutes },
                    distanceKm: currentUserID.flatMap { homeViewModel.currentUserTripState(for: activeTrip, userID: $0)?.distanceKm },
                    isOwner: currentUserID.map { homeViewModel.isOwner(of: activeTrip, userID: $0) } ?? false,
                    isUpdatingTripStatus: homeViewModel.isUpdatingTripStatus,
                    tripActionErrorMessage: homeViewModel.tripActionErrorMessage,
                    onEndTrip: {
                        Task { await homeViewModel.endTrip(activeTrip) }
                    },
                    onLeaveTrip: {
                        Task { await homeViewModel.leaveTrip(activeTrip) }
                    }
                )
                .task(id: activeTrip.id) {
                    // See HomeView's equivalent .task.
                    while !Task.isCancelled {
                        await homeViewModel.refreshTripStatus(for: activeTrip)
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                    }
                }
            } else {
                ZStack {
                    Image(.homeBackground)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 24) {
                            Picker("", selection: $selectedSegment) {
                                ForEach(TripListSegment.allCases) { segment in
                                    Text(segment.title)
                                        .tag(segment)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)

                            tripsMenu
                        }
                        .padding(.top, 120)
                        .padding(.bottom, 40)
                    }
                    .navigationTitle("Your trips")
                    .navigationBarTitleDisplayMode(.inline)
                    .presentationBackground(.clear)
                }
                .searchable(
                    text: $searchText,
                    placement: .toolbar,
                    prompt: "Search trips..."
                )
            }
        }
        .task {
            await homeViewModel.loadTrips()
            currentUserID = try? await homeViewModel.currentUserID()
        }
    }

    private var tripsMenu: some View {
        VStack(spacing: 0) {
            ForEach(displayedTrips) { trip in
                NavigationLink {
                    ProfileTripDetailsView(trip: trip)
                } label: {
                    TripMenuRow(trip: trip)
                }
                .buttonStyle(.plain)

                if trip.id != displayedTrips.last?.id {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: 362)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

enum TripListSegment: String, CaseIterable, Identifiable {
    case totalTrips
    case nextTrips

    var id: String { rawValue }

    var title: String {
        switch self {
        case .totalTrips:
            return "All Trips"
        case .nextTrips:
            return "Upcoming Trips"
        }
    }
}

struct TripMenuRow: View {
    let trip: Trip

    private var hasPassed: Bool {
        trip.startDate < Calendar.current.startOfDay(for: .now)
    }

    private var formattedDate: String {
        trip.startDate.formatted(
            Date.FormatStyle()
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.title)
                    .font(.bodyText())
                    .lineLimit(1)

                Text(formattedDate)
                    .font(.callout())
                    .foregroundStyle(
                        hasPassed
                        ? Color(hex: "#3C3C43").opacity(0.6)
                        : Color.green
                    )
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.title3())
                .foregroundStyle(.tertiary)
        }
        .frame(height: 68)
        .contentShape(Rectangle())
    }
}

struct PlaceholderTrip: Identifiable {
    let id = UUID()

    let name: String
    let startDate: Date
    let meetTime: Date

    let ownerUsername: String

    let locationName: String
    let locationAddress: String
    let locationNote: String

    let memberCount: Int
    let invitationCode: String
}

extension PlaceholderTrip {

    static let samples: [PlaceholderTrip] = [

        PlaceholderTrip(
            name: "Kuta Sunset Surf and Chill",
            startDate: Calendar.current.date(
                from: DateComponents(year: 2026, month: 6, day: 30)
            )!,
            meetTime: Calendar.current.date(
                from: DateComponents(hour: 17)
            )!,
            ownerUsername: "Bintang",
            locationName: "Toko Kopi Jaya, Kuta",
            locationAddress: "Jl. Dewi Sri No. 99X, Legian, Bali 80361",
            locationNote: "Luat's House • Room 222",
            memberCount: 6,
            invitationCode: "1A6B7K"
        ),

        PlaceholderTrip(
            name: "Nusa Dua Beach Day",
            startDate: .now.addingTimeInterval(86400 * 10),
            meetTime: Calendar.current.date(
                from: DateComponents(hour: 9)
            )!,
            ownerUsername: "Baeni",
            locationName: "Nusa Dua Beach",
            locationAddress: "Badung, Bali",
            locationNote: "Meet at the entrance",
            memberCount: 5,
            invitationCode: "NUSA88"
        )
    ]
}

#Preview("Many Trips") {
    NavigationStack {
        TripsListView_ManyTripsPreview()
    }
}

/// A thin wrapper that injects many sample trips into the TripsListView's
/// local state so we can preview scrolling behaviour.
private struct TripsListView_ManyTripsPreview: View {
    private static let sampleNames: [String] = [
        "Kuta Sunset Surf and Chill",
        "Nusa Dua Beach Day",
        "Ubud Temple Tour",
        "Seminyak Night Out",
        "Mount Batur Sunrise Hike",
        "Tanah Lot Sunset Visit",
        "Sanur Snorkeling Trip",
        "Canggu Brunch Crawl",
        "Jimbaran Seafood Dinner",
        "Uluwatu Cliff Adventure",
        "Lovina Dolphin Watch",
        "Tegallalang Rice Terraces",
        "Denpasar Market Walk",
        "Nusa Penida Day Trip",
        "Gili Islands Getaway",
    ]

    private static let dummyOwnerID = CKRecord.ID(recordName: "previewOwner")

    private static func makeSampleTrips() -> [Trip] {
        sampleNames.enumerated().map { index, name in
            let dayOffset = Double(index * 3 - 10)
            let start = Date.now.addingTimeInterval(86400 * dayOffset)
            return Trip(
                id: CKRecord.ID(recordName: "trip-\(index)"),
                title: name,
                destination: "Bali, Indonesia",
                startDate: start,
                endDate: start.addingTimeInterval(86400),
                ownerID: dummyOwnerID,
                invitationCode: String(format: "%06X", Int.random(in: 0...0xFFFFFF)),
                status: .notStarted,
                createdAt: .now,
                updatedAt: .now
            )
        }
    }

    @State private var selectedSegment: TripListSegment = .totalTrips
    @State private var searchText = ""
    private let trips = makeSampleTrips()

    private var displayedTrips: [Trip] {
        let today = Calendar.current.startOfDay(for: .now)
        let segmentTrips: [Trip] = switch selectedSegment {
        case .totalTrips: trips
        case .nextTrips: trips.filter { $0.startDate >= today }
        }
        guard !searchText.isEmpty else { return segmentTrips }
        return segmentTrips.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Picker("", selection: $selectedSegment) {
                        ForEach(TripListSegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        ForEach(displayedTrips) { trip in
                            TripMenuRow(trip: trip)
                                .padding(.horizontal, 20)
                            if trip.id != displayedTrips.last?.id {
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .frame(width: 362)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
                .padding(.top, 120)
                .padding(.bottom, 40)
            }
            .navigationTitle("Your Trips")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search trips...")
    }
}
