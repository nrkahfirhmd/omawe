//
//  TripHeaderCard.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 06/07/26.
//

import SwiftUI
import CloudKit

struct TripHeaderCard: View {
    @Binding var isExpanded: Bool
    let trip: Trip
    var participants: [Participant] = []
    var participantStates: [CKRecord.ID: ParticipantTripState] = [:]
    var currentUserID: CKRecord.ID? = nil

    private var ownEtaMinutes: Int? {
        currentUserID.flatMap { participantStates[$0]?.etaMinutes }
    }

    private var ownDistanceKm: Double? {
        currentUserID.flatMap { participantStates[$0]?.distanceKm }
    }

    var body: some View {
        VStack(spacing: 12) {
            TripHeader(trip: trip)

            HeaderStats(
                peopleCount: max(participants.count, 1),
                etaMinutes: ownEtaMinutes,
                distanceKm: ownDistanceKm
            )

            if isExpanded {
                Divider()
                    .background(Color.white)

                ExpandedContent(
                    participants: participants,
                    participantStates: participantStates,
                    currentUserID: currentUserID
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }

            VStack {
                Capsule()
                    .frame(width: 75, height: 5)
            }
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .frame(maxWidth: .infinity)
        .background(GridGradientBackground(color: Theme.secondaryBox))
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .animation(.spring(duration: 0.45), value: isExpanded)
        .foregroundStyle(.white)
    }
}

private struct TripHeader: View {
    let trip: Trip

    private var ownerName: String {
        trip.ownerDisplayName ?? "Anonymous"
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(trip.title.isEmpty ? "Untitled trip" : trip.title)
                .font(.headline())
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("by @\(ownerName) • \(trip.startDate.formatted(.dateTime.day().month(.twoDigits).year())) • \(trip.startDate.formatted(date: .omitted, time: .shortened))")
                .font(.caption1())
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}

private struct HeaderStats: View {
    var peopleCount: Int = 1
    var etaMinutes: Int? = nil
    var distanceKm: Double? = nil

    var body: some View {
        HStack(spacing: 0) {
            stat(title: "People", value: "\(peopleCount)")

            Divider()
                .frame(height: 70)
                .background(Color.white)

            stat(title: "ETA", value: etaMinutes.map { "\($0)m" } ?? "--", color: .yellow)

            Divider()
                .frame(height: 70)
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

/// Pages through every participant on the trip one at a time, showing
/// their live status (ETA-2) — not just the current device's own state,
/// which `HeaderStats` above already covers.
private struct ExpandedContent: View {
    let participants: [Participant]
    let participantStates: [CKRecord.ID: ParticipantTripState]
    let currentUserID: CKRecord.ID?

    @State private var selectedIndex = 0

    private var current: Participant? {
        guard participants.indices.contains(selectedIndex) else { return nil }
        return participants[selectedIndex]
    }

    private var currentState: ParticipantTripState? {
        current.flatMap { participantStates[$0.userID] }
    }

    private var displayName: String {
        guard let current else { return "No one on this trip yet" }
        if current.userID == currentUserID {
            return "\(current.displayName ?? "You") (You)"
        }
        return current.displayName ?? "Member \(String(current.userID.recordName.suffix(6)))"
    }

    var body: some View {
        VStack(spacing: 28) {
            Button {
            } label: {
                Label("Gonna be late", systemImage: "message.badge")
                    .padding(.horizontal)
                    .font(.caption1())
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown.opacity(0.8))

            HStack {
                Button {
                    guard !participants.isEmpty else { return }
                    selectedIndex = (selectedIndex - 1 + participants.count) % participants.count
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(participants.count < 2)

                Spacer()

                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)

                    if let currentState {
                        Text(currentState.status.label)
                            .font(.caption1())
                            .foregroundStyle(currentState.status.tint)

                        Text([
                            currentState.etaMinutes.map { "\($0)m" },
                            String(format: "%.1fkm", currentState.distanceKm)
                        ].compactMap { $0 }.joined(separator: " • "))
                        .font(.caption2())
                        .foregroundStyle(.secondary)
                    } else if current != nil {
                        Text("Waiting for location…")
                            .font(.caption1())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    guard !participants.isEmpty else { return }
                    selectedIndex = (selectedIndex + 1) % participants.count
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(participants.count < 2)
            }

            HStack(spacing: 16) {
                Image(systemName: "location.fill")
                Capsule().fill(currentState?.status.tint.opacity(0.6) ?? .white.opacity(0.35)).frame(height: 6)
                Image(systemName: "flag.fill")
            }
        }
        .padding(.top, 8)
        .onChange(of: participants.count) { _, newCount in
            if selectedIndex >= newCount {
                selectedIndex = max(0, newCount - 1)
            }
        }
    }
}

private extension ParticipantTripStatus {
    var label: String {
        switch self {
        case .onTheWay: return "On the way"
        case .nearDestination: return "Almost there"
        case .delayed: return "Running late"
        case .offline: return "Offline"
        case .arrived: return "Arrived"
        }
    }

    var tint: Color {
        switch self {
        case .onTheWay: return .yellow
        case .nearDestination: return .cyan
        case .delayed: return .orange
        case .offline: return .gray
        case .arrived: return .green
        }
    }
}

#Preview {
    TripHeaderCard(
        isExpanded: .constant(false),
        trip: Trip(
            id: CKRecord.ID(recordName: "dummy-trip"),
            title: "Ex-Boyfriends Celebration!",
            destination: "Toko Kopi Jaya, Kuta",
            startDate: .now,
            endDate: .now,
            ownerID: CKRecord.ID(recordName: "Bintang"),
            ownerDisplayName: "Bintang",
            invitationCode: "1A6B7K",
            status: .active,
            createdAt: .now,
            updatedAt: .now
        )
    )
}
