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
    @State private var participantLocations: [CKRecord.ID: Location] = [:]
    @State private var currentUserRoute: MKRoute?
    @State private var lastRouteOrigin: CLLocationCoordinate2D?
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

    /// Participants other than the current device — the current user is
    /// already shown via the map's built-in `UserAnnotation`.
    private var otherParticipantAnnotations: [(id: CKRecord.ID, name: String, coordinate: CLLocationCoordinate2D)] {
        participantLocations.compactMap { userID, location in
            guard userID != currentUserID else { return nil }
            let name = participants.first { $0.userID == userID }?.displayName ?? "Member \(String(userID.recordName.suffix(6)))"
            return (userID, name, location.coordinate)
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
                        ParticipantPin(displayName: entry.name)
                    }
                }

                if let currentUserRoute {
                    MapPolyline(currentUserRoute)
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
                    try? await Task.sleep(nanoseconds: 20_000_000_000)
                }
            }

            // MARK: Overlay
            VStack {
                TripHeaderCard(
                    isExpanded: $isHeaderExpanded,
                    trip: trip,
                    participants: participants,
                    participantStates: tripStatusViewModel.participantStates,
                    currentUserID: currentUserID
                )
                    .onTapGesture {
                        HapticManager.shared.boom()

                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            isHeaderExpanded.toggle()
                        }
                    }

                Spacer()

                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)

                        Text("Your report has been recorded")
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())

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
                        } label: {
                            Text("Report")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            Color.cyan,
                                            lineWidth: 2
                                        )
                                }
                                .clipShape(
                                    Capsule()
                                )
                        }

                        Spacer()

                        Button {
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.black)
                                .frame(width: 62, height: 62)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Fetches every participant's latest location for annotations, and
    /// (only for the current user — routing every participant would burn
    /// through MKDirections' rate limit for no real benefit on a shared map)
    /// refreshes the route polyline when the current user has moved past a
    /// meaningful threshold since the last request.
    private func refreshParticipantLocations(tripID: CKRecord.ID) async {
        do {
            let samples = try await locationSyncService.fetchLatestLocations(for: tripID)
            participantLocations = samples.mapValues { Location(latitude: $0.latitude, longitude: $0.longitude) }
        } catch {
            return
        }

        guard let currentUserID,
              let destination = trip.destinationCoordinate,
              let origin = participantLocations[currentUserID]?.coordinate else { return }

        if let lastRouteOrigin {
            let moved = LocationCore.straightLineDistance(
                from: Location(coordinate: lastRouteOrigin),
                to: Location(coordinate: origin)
            )
            guard moved >= 200 else { return }
        }

        await loadRoute(from: origin, to: destination)
        lastRouteOrigin = origin
    }

    /// Recomputes every participant's ETA/distance/status (ETA-1/ETA-2) so
    /// `TripHeaderCard` can show each person's live status, not just pin
    /// positions on the map.
    private func refreshParticipantStatuses(tripID: CKRecord.ID) async {
        guard let destination = trip.destinationCoordinate else { return }
        await tripStatusViewModel.refresh(tripID: tripID, destination: destination)
    }

    private func loadRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: origin.latitude, longitude: origin.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            currentUserRoute = response.routes.first
        } catch {
            currentUserRoute = nil
        }
    }
}

private struct ParticipantPin: View {
    let displayName: String

    private var initials: String {
        let initials = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.omawePrimary, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
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
