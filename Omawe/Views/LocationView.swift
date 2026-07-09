//
//  LocationView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI
import MapKit
import CloudKit

struct LocationView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    var participants: [Participant] = []
    var currentUserID: CKRecord.ID? = nil
    
    @Environment(\.openURL) var openURL

    @State private var camera: MapCameraPosition = .userLocation(
        fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: -8.748,
                    longitude: 115.167
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: 0.12,
                    longitudeDelta: 0.12
                )
            )
        )
    )
    @State private var isHeaderExpanded = false
    private var isReportedLate: Bool {
        guard let currentUserID else { return false }
        return tripStatusViewModel.participantStates[currentUserID]?.status == .delayed
    }
    // Shared with TripHeaderCard's status display — set by the danger
    // button below, distinct from (and more urgent than) `isReportedLate`.
    @State private var needsHelp = false
    // Transient confirmation toast — separate from the persistent
    // `isReportedLate`/`needsHelp` status so it can auto-dismiss without
    // clearing the underlying report.
    @State private var confirmationMessage: String? = nil
    @State private var bannerDismissTask: Task<Void, Never>?
    // Full samples (not just coordinates) so NFR-1 can tell "never received"
    // (absent from this dict) apart from "received, but old" (present with a
    // stale `recordedAt`) — a plain `[CKRecord.ID: Location]` couldn't
    // distinguish those two cases.
    @State private var participantSamples: [CKRecord.ID: LocationSample] = [:]
    
    private final class DebouncerCache {
        var debouncers: [CKRecord.ID: StaleDisplayDebouncer] = [:]
        func debouncer(for id: CKRecord.ID) -> StaleDisplayDebouncer {
            if let existing = debouncers[id] { return existing }
            let new = StaleDisplayDebouncer()
            debouncers[id] = new
            return new
        }
    }
    private let debouncerCache = DebouncerCache()

    // NFR-4: auto-fits once when the set of participants with a known
    // location changes (e.g. someone's first fix lands), not on every ~20s
    // poll tick — satisfies the ticket's "don't fight the user's manual
    // navigation on every location update" by only re-fitting on structural
    // changes, rather than attempting to distinguish a manual gesture from a
    // programmatic camera move (SwiftUI's `Map` has no reliable seam for
    // that distinction today).
    @State private var lastFittedParticipantIDs: Set<CKRecord.ID> = []
    private let locationService = LocationService()
    private let locationSyncService = CloudKitLocationSyncService()
    // Drives TripHeaderCard's per-participant status (ETA-2) — separate
    // instance from HomeViewModel's, since this view has no reference to it.
    @State private var tripStatusViewModel: TripStatusViewModel

    init(trip: Trip, participants: [Participant] = [], currentUserID: CKRecord.ID? = nil) {
        self.trip = trip
        self.participants = participants
        self.currentUserID = currentUserID
        _tripStatusViewModel = State(initialValue: TripStatusViewModel(locationSyncService: CloudKitLocationSyncService()))
    }

    /// NFR-1: this device's own permission-related banner state — denied/
    /// restricted gets a Settings deep-link prompt, reduced accuracy gets a
    /// lighter notice, fully-authorized shows nothing.
    private var permissionDisplayState: PermissionDisplayState {
        PermissionDisplayState.from(locationService.authorizationState)
    }

    /// Shows `text` as a toast and auto-dismisses it after a few seconds.
    /// Cancels any pending dismiss first so back-to-back taps (Report then
    /// the danger button) don't race and clear each other's message early.
    private func showConfirmationBanner(_ text: String) {
        bannerDismissTask?.cancel()
        withAnimation { confirmationMessage = text }
        bannerDismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation { confirmationMessage = nil }
        }
    }

    /// Participants other than the current device — the current user is
    /// already shown via the map's built-in `UserAnnotation`.
    private var otherParticipantAnnotations: [(id: CKRecord.ID, name: String, coordinate: CLLocationCoordinate2D, displayState: ParticipantLocationDisplayState)] {
        participantSamples.compactMap { userID, sample in
            guard userID != currentUserID else { return nil }
            let name = participants.first { $0.userID == userID }?.displayName ?? "Member \(String(userID.recordName.suffix(6)))"
            let coordinate = CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude)
            return (userID, name, coordinate, displayState(for: userID, lastUpdated: sample.recordedAt))
        }
    }

    var body: some View {
        ZStack {
            // MARK: Map
            Map(position: $camera) {
                UserAnnotation()

                if let destinationCoordinate = trip.destinationCoordinate {
                    Marker(
                        trip.destination.isEmpty ? "Destination" : trip.destination,
                        systemImage: "flag.checkered",
                        coordinate: destinationCoordinate
                    )
                    .tint(.red)
                }

                ForEach(otherParticipantAnnotations, id: \.id) { entry in
                    Annotation(entry.name, coordinate: entry.coordinate) {
                        ParticipantPin(displayName: entry.name, displayState: entry.displayState)
                    }
                }

                // NFR-4: reuses ETA-1's already-computed route (`TripStatusViewModel`)
                // instead of this view issuing its own second, redundant
                // `MKDirections` request for the same origin/destination.
                if let currentUserID, let route = tripStatusViewModel.route(for: currentUserID) {
                    MapPolyline(route)
                        .stroke(Color.omawePrimary, lineWidth: 5)
                }
            }
            .ignoresSafeArea()
            .task {
                // Map's built-in user-location dot/tracking needs authorization
                // requested at least once — reuses the same LocationService
                // wrapper LOC-2/HomeViewModel use, not a bare CLLocationManager call.
                locationService.requestWhenInUseAuthorization()
            }
            .task(id: trip.id) {
                guard let tripID = trip.id else { return }
                // Polls at roughly LOC-1's propagation budget, same cadence
                // as HomeView's ETA refresh — there's no push-triggered
                // recompute path yet.
                while !Task.isCancelled {
                    await refreshParticipantLocations(tripID: tripID)
                    await refreshParticipantStatuses(tripID: tripID)
                    fitRegionIfParticipantsChanged()
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                }
            }

            // MARK: Overlay
            VStack {
                TripHeaderCard(
                    isExpanded: $isHeaderExpanded,
                    trip: trip,
                    participants: participants,
                    participantStates: tripStatusViewModel.participantStates,
                    currentUserID: currentUserID,
                    needsHelp: $needsHelp
                )
                    .onTapGesture {
                        HapticManager.shared.boom()

                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            isHeaderExpanded.toggle()
                        }
                    }

                if permissionDisplayState != .none {
                    PermissionBanner(state: permissionDisplayState)
                        .padding(.top, 10)
                }

                Spacer()

                VStack(spacing: 18) {
                    if let confirmationMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)

                            Text(confirmationMessage)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    HStack(alignment: .bottom) {
                        Button {
                            HapticManager.shared.boom()

                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.black)
                                .frame(width: 62, height: 62)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button {
                            HapticManager.shared.boom()
                            openURL(URL(string: "omawe://report")!)
                            if !isReportedLate {
                                needsHelp = false
                                showConfirmationBanner("Your report has been recorded")
                            } else {
                                showConfirmationBanner("Your report has been cleared")
                            }
                        } label: {
                            Text(isReportedLate ? "Reported" : "Report")
                                .font(.button())
                                .fontWidth(.expanded)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            isReportedLate ? Color.red : Color.cyan,
                                            lineWidth: 2
                                        )
                                }
                        }
                        .glassEffect(.clear)

                        Spacer()

                        Button {
                            HapticManager.shared.boom()
                            needsHelp.toggle()
                            if needsHelp {
                                showConfirmationBanner("Your help request has been sent")
                            } else {
                                showConfirmationBanner("Your help request has been cleared")
                            }
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(needsHelp ? .white : .black)
                                .frame(width: 62, height: 62)
                                .background(needsHelp ? AnyShapeStyle(Color.red) : AnyShapeStyle(.ultraThinMaterial))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Fetches every participant's latest location for annotations. Route
    /// computation is no longer this view's job (NFR-4) — `refreshParticipantStatuses`
    /// below drives `TripStatusViewModel`, which already resolves and caches
    /// the current user's route for ETA purposes; the map just reads it.
    private func refreshParticipantLocations(tripID: CKRecord.ID) async {
        do {
            let samples = try await locationSyncService.fetchLatestLocations(for: tripID)
            participantSamples = samples
        } catch {
            return
        }
    }

    /// Recomputes every participant's ETA/distance/status (ETA-1/ETA-2) so
    /// `TripHeaderCard` can show each person's live status, not just pin
    /// positions on the map.
    private func refreshParticipantStatuses(tripID: CKRecord.ID) async {
        guard let destination = trip.destinationCoordinate else { return }
        await tripStatusViewModel.refresh(tripID: tripID, destination: destination)
    }

    /// NFR-1: derives this participant's display state (normal/stale/
    /// unavailable) from LOC-1's `recordedAt` (via `hasEverReceivedLocation`)
    /// and ETA-2's `isStale` signal, run through a per-participant debouncer
    /// so a reading right at the 30s staleness boundary doesn't flicker.
    private func displayState(for userID: CKRecord.ID, lastUpdated: Date) -> ParticipantLocationDisplayState {
        let raw = ParticipantLocationDisplayState.from(
            hasEverReceivedLocation: true,
            isStale: tripStatusViewModel.participantStates[userID]?.isStale ?? false,
            lastUpdated: lastUpdated
        )

        let debouncer = debouncerCache.debouncer(for: userID)
        return debouncer.display(for: raw)
    }

    /// NFR-4: auto-fit/zoom to show every participant with a known location
    /// plus the destination — only re-runs when the *set* of participants
    /// with a location changes, so it doesn't re-center on every routine
    /// poll tick (see the `lastFittedParticipantIDs` doc comment above).
    private func fitRegionIfParticipantsChanged() {
        let currentIDs = Set(participantSamples.keys)
        guard currentIDs != lastFittedParticipantIDs else { return }
        lastFittedParticipantIDs = currentIDs

        var coordinates = participantSamples.values.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        if let destination = trip.destinationCoordinate {
            coordinates.append(destination)
        }

        guard let region = MapRegionFitting.fitRegion(coordinates: coordinates) else { return }
        withAnimation(.easeInOut) {
            camera = .region(region)
        }
    }
}

private struct PermissionBanner: View {
    let state: PermissionDisplayState

    private var message: String {
        switch state {
        case .deniedOrRestricted:
            return "Location access is off, so your travel companions can't see you on the map."
        case .reducedAccuracy:
            return "Using an approximate location — precise location is off."
        case .none:
            return ""
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(.white)

            Text(message)
                .font(.caption)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            if state == .deniedOrRestricted {
                Spacer(minLength: 8)

                Button("Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.caption.bold())
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.55), in: Capsule())
        .padding(.horizontal, 18)
    }
}

private struct ParticipantPin: View {
    let displayName: String
    var displayState: ParticipantLocationDisplayState = .normal

    private var initials: String {
        let initials = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }

    /// NFR-1/NFR-4: a stale pin is dimmed and annotated with how long ago it
    /// was last updated, rather than rendering identically to a fresh one —
    /// showing a precise-looking position for out-of-date data would be
    /// misleading.
    private var isStale: Bool {
        if case .stale = displayState { return true }
        return false
    }

    private var staleCaption: String? {
        guard case .stale(let lastUpdated) = displayState else { return nil }
        let minutes = max(1, Int(Date().timeIntervalSince(lastUpdated) / 60))
        return "\(minutes)m ago"
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(initials)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.omawePrimary.opacity(isStale ? 0.45 : 1), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .opacity(isStale ? 0.6 : 1)

            if let staleCaption {
                Text(staleCaption)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.6), in: Capsule())
            }
        }
    }
}

#Preview {
    LocationView(
        trip: Trip(
            id: CKRecord.ID(recordName: "dummy-trip"),
            title: "Ex-boyfriends Celebration",
            destination: "Toko Kopi Jaya, Kuta",
            startDate: .now,
            endDate: .now,
            ownerID: CKRecord.ID(recordName: "Bintang"),
            invitationCode: "1A6B7K",
            status: .active,
            createdAt: .now,
            updatedAt: .now
        )
    )
}
