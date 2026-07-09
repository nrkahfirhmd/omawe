//
//  OnTripView.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 07/07/26.
//

import SwiftUI
import CloudKit

struct OnTripView: View {
    let trip: Trip
    var participantCount: Int = 1
    var participants: [Participant] = []
    var participantStates: [CKRecord.ID: ParticipantTripState] = [:]
    var currentUserID: CKRecord.ID? = nil
    var etaMinutes: Int? = nil
    var distanceKm: Double? = nil
    var isOwner: Bool = false
    var isUpdatingTripStatus: Bool = false
    var tripActionErrorMessage: String? = nil
    var onEndTrip: () -> Void = {}
    var onLeaveTrip: () -> Void = {}

    private var shortOwnerID: String {
        String(trip.ownerID.recordName.suffix(6))
    }

    private var mates: [OmaweWidgetAttributes.MateProgress] {
        OmaweWidgetAttributes.MateProgress.markers(
            participants: participants,
            participantStates: participantStates,
            currentUserID: currentUserID
        )
    }

    private var subtitle: String {
        [
            "by @\(UserSession.shared.displayName ?? "Anonymous")",
            trip.startDate.formatted(.dateTime.day().month(.twoDigits).year()),
            trip.startDate.formatted(date: .omitted, time: .shortened)
        ].joined(separator: " • ")
    }

    var body: some View {
        DynamicBox(
            theme: Theme.themeTertiary,
            icon: "",
            title: trip.title.isEmpty ? "Untitled trip" : trip.title,
            subtitle: subtitle,
            helperText: "",
            footerTitle: "You're on this trip"
        ) {
//            ZStack {
//                GIFView(name: "on_trip")
//                    .ignoresSafeArea()
//                    .frame(width: .infinity)
//                    .frame(height: 220)
//                    .mask(
//                        LinearGradient(
//                            stops: [
//                                .init(color: .clear, location: 0),
//                                .init(color: .white, location: 0.25),
//                                .init(color: .white, location: 0.85),
//                                .init(color: .clear, location: 1)
//                            ],
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//
//                LinearGradient(
//                    colors: [
//                        .black.opacity(0.7),
//                        .clear,
//                        .black.opacity(0.95)
//                    ],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//            }
            
            VStack(spacing: 14) {
                // MARK: - Route Progress View
                RouteProgressView(mates: mates)
                
                VStack(spacing: 12) {
                    Label(trip.destination.isEmpty ? "Location unavailable" : trip.destination, systemImage: "location")
                        .font(.caption1().bold())

                    HeaderStats(peopleCount: participantCount, etaMinutes: etaMinutes, distanceKm: distanceKm)

                    NavigationLink {
                        LocationView(trip: trip, participants: participants, currentUserID: currentUserID)
                    } label: {
                        ZStack {
                            Capsule()
                                .foregroundStyle(.ultraThinMaterial)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)

                            Label("View on Map", systemImage: "map")
                                .font(.button())
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(GridGradientBackground(color: Theme.tertiaryBox))
                .border(Color.white.opacity(0.1), width: 2)
                .clipShape(RoundedRectangle(cornerRadius: 35))

                if let tripActionErrorMessage {
                    Text(tripActionErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if isOwner {
                    Button(role: .destructive, action: onEndTrip) {
                        Text("End trip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isUpdatingTripStatus)
                } else {
                    Button(role: .destructive, action: onLeaveTrip) {
                        Text("Leave trip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 24)
        }
        .transition(.scale(scale: 0.18, anchor: .top).combined(with: .opacity))
    }
}

private struct HeaderStats: View {
    var peopleCount: Int = 1
    var etaMinutes: Int? = nil
    var distanceKm: Double? = nil

    var body: some View {
        HStack(spacing: 0) {
            stat(title: "People", value: "\(peopleCount)", color: .omawePrimary)

            Divider()
                .frame(height: 40)
                .background(Color.white)

            // "--" until TripStatusViewModel (ETA-1) has computed a real
            // reading for this device — not a fabricated number.
            stat(title: "ETA", value: etaMinutes.map { "\($0)m" } ?? "--", color: .yellow)

            Divider()
                .frame(height: 40)
                .background(Color.white)

            stat(title: "Distance", value: distanceKm.map { String(format: "%.1fkm", $0) } ?? "--", color: .yellow)
        }
    }

    @ViewBuilder
    private func stat(title: String, value: String, color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2())
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.button())
                .foregroundStyle(color)
                .fontWidth(.expanded)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        OnTripView(
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
            ),
            participantCount: 12
        )
    }
}
