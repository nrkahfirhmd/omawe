//
//  WidgetContentStateAggregator.swift
//  Omawe
//

import CloudKit

/// Reshapes ETA-2's per-participant states into the widget's single-string
/// rollup. `ContentState` has exactly one `statusMessage`/`etaMinutes`/
/// `distanceKm` for a trip that can have many participants — there's no
/// product-confirmed selection policy for which participant "wins" (see
/// ETA-3's "Confirmed ambiguity"). Pending real product sign-off, this picks
/// whoever is currently furthest from arrival — i.e. most likely to need
/// attention/a nudge — since that's the participant a Live Activity viewer
/// would plausibly care about most. This is an engineering default, not a
/// confirmed decision — flag for product review before shipping.
enum WidgetContentStateAggregator {

    /// - Parameters:
    ///   - participantStates: One state per participant currently reporting
    ///     a location (ETA-1/ETA-2 output).
    ///   - displayNames: Participant display names for the third-person
    ///     `statusMessage` copy (e.g. "Bintang is on the way").
    static func aggregate(
        participantStates: [ParticipantTripState],
        displayNames: [CKRecord.ID: String]
    ) -> OmaweWidgetAttributes.ContentState {
        let arrivedCount = participantStates.count { $0.status == .arrived }

        guard let selected = select(from: participantStates) else {
            // Zero participants reporting yet (trip just started, no LOC-1
            // data has arrived) or everyone has arrived — define a sensible
            // default rather than crashing on an empty aggregation.
            let statusMessage = arrivedCount > 0 ? "Everyone has arrived" : "Waiting for location updates"
            return OmaweWidgetAttributes.ContentState(
                statusMessage: statusMessage,
                etaMinutes: 0,
                arrivedCount: arrivedCount,
                distanceKm: 0
            )
        }

        let name = displayNames[selected.userID] ?? "Someone"

        return OmaweWidgetAttributes.ContentState(
            statusMessage: message(for: selected, name: name),
            etaMinutes: selected.etaMinutes ?? 0,
            arrivedCount: arrivedCount,
            distanceKm: selected.distanceKm
        )
    }

    /// Furthest-from-arrival among non-arrived participants; nil if there
    /// are none (empty trip or everyone already arrived).
    static func select(from participantStates: [ParticipantTripState]) -> ParticipantTripState? {
        participantStates
            .filter { $0.status != .arrived }
            .max { lhs, rhs in
                if lhs.distanceKm != rhs.distanceKm { return lhs.distanceKm < rhs.distanceKm }
                return lhs.userID.recordName > rhs.userID.recordName
            }
    }

    private static func message(for state: ParticipantTripState, name: String) -> String {
        switch state.status {
        case .offline:
            return "\(name)'s location is unavailable"
        case .delayed:
            return "\(name) is running late"
        case .nearDestination:
            return "\(name) is almost there"
        case .onTheWay, .arrived:
            return "\(name) is on the way"
        }
    }
}
