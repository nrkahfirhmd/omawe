//
//  RouteProgressView.swift
//  Omawe
//
//  In-app port of OmaweWidget's Live Activity route visualization
//  (`OmaweWidgetLiveActivityView.RouteProgressView`) — same curved path,
//  distance-based marker placement, and clustering logic, so the trip
//  screens match what's shown on the lock screen / Dynamic Island.
//

import SwiftUI
import CloudKit

// MARK: - Route Progress View
struct RouteProgressView: View {
    let mates: [OmaweWidgetAttributes.MateProgress]

    private var markers: [(position: CGFloat, label: String, isMe: Bool, clusterText: String?, distanceKm: Double)] {
        let sorted = mates.sorted { $0.distanceKm > $1.distanceKm }
        let maxDistance = sorted.first?.distanceKm ?? 1.0
        let scale = maxDistance > 0 ? maxDistance : 1.0

        var clusters: [(position: CGFloat, label: String, isMe: Bool, clusterText: String?, distanceKm: Double)] = []

        for mate in sorted {
            let pos = CGFloat(1.0 - (mate.distanceKm / scale))

            if let lastIndex = clusters.indices.last, abs(clusters[lastIndex].position - pos) < 0.05 {
                let existing = clusters[lastIndex]
                let currentExtra = existing.clusterText == nil ? 0 : (Int(existing.clusterText!.dropFirst()) ?? 0)
                clusters[lastIndex] = (existing.position, existing.label, existing.isMe || mate.isMe, "+\(currentExtra + 1)", existing.distanceKm)
            } else {
                clusters.append((pos, mate.label, mate.isMe, nil, mate.distanceKm))
            }
        }
        return clusters
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midY = geo.size.height / 2

            Path { path in
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: w, y: midY))
            }
            .stroke(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.9), location: 0.5),
                        .init(color: .white.opacity(0), location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 3)

            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.3), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .rotationEffect(.degrees(45))
                .position(
                    x: 0,
                    y: midY
                )

            Image(systemName: "flag.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.4), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                ))
                .position(
                    x: w,
                    y: midY
                )

            ForEach(Array(markers.enumerated()), id: \.offset) { _, marker in
                MateMarkerView(
                    label: marker.label,
                    isMe: marker.isMe,
                    clusterText: marker.clusterText,
                    distanceKm: marker.distanceKm
                )
                .position(
                    x: w * marker.position,
                    y: midY
                )
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Mate Marker View
struct MateMarkerView: View {
    let label: String
    let isMe: Bool
    let clusterText: String?
    let distanceKm: Double

    private var bgColor: Color {
        distanceKm <= 0.5 ? .green : .orange
    }

    @ViewBuilder
    private var markerView: some View {
        if isMe {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .frame(width: 32, height: 32)

                Image(systemName: "location.north.fill")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(90))
            }
        } else {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(minWidth: 23, minHeight: 28)
                .background(bgColor)
                .clipShape(Capsule())
        }
    }

    var body: some View {
        if let clusterText {
            ZStack(alignment: .topTrailing) {
                markerView

                Text(clusterText)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 18, height: 18)
                    .background(Color.white)
                    .clipShape(Circle())
                    .offset(x: 8, y: -4)
            }
        } else {
            markerView
        }
    }
}

// MARK: - Mate marker construction
extension OmaweWidgetAttributes.MateProgress {
    /// One marker per participant with a known live state — mirrors
    /// `WidgetContentStateAggregator`'s mate list so the in-app route
    /// matches the Live Activity.
    static func markers(
        participants: [Participant],
        participantStates: [CKRecord.ID: ParticipantTripState],
        currentUserID: CKRecord.ID?
    ) -> [OmaweWidgetAttributes.MateProgress] {
        participants.compactMap { participant in
            guard let state = participantStates[participant.userID] else { return nil }
            let name = participant.displayName ?? "Someone"
            return OmaweWidgetAttributes.MateProgress(
                label: String(name.prefix(1)).uppercased(),
                distanceKm: state.distanceKm,
                isMe: participant.userID == currentUserID
            )
        }
    }
}

#Preview {
    RouteProgressView(mates: [
        OmaweWidgetAttributes.MateProgress(label: "B", distanceKm: 15.0, isMe: false),
        OmaweWidgetAttributes.MateProgress(label: "K", distanceKm: 14.8, isMe: false),
        OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 10.0, isMe: true),
        OmaweWidgetAttributes.MateProgress(label: "C", distanceKm: 0.2, isMe: false)
    ])
    .padding()
    .background(Color.black)
}
