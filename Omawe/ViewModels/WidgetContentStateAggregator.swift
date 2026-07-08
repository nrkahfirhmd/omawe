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
        displayNames: [CKRecord.ID: String],
        currentUserID: CKRecord.ID? = nil
    ) -> OmaweWidgetAttributes.ContentState {
        let arrivedCount = participantStates.count { $0.status == .arrived }
        
        let mates = participantStates.map { state -> OmaweWidgetAttributes.MateProgress in
            let name = displayNames[state.userID] ?? "Someone"
            let initial = String(name.prefix(1)).uppercased()
            let isMe = state.userID == currentUserID
            return OmaweWidgetAttributes.MateProgress(
                label: initial,
                distanceKm: state.distanceKm,
                isMe: isMe
            )
        }
        
        var myEtaMinutes = 0
        var myDistanceKm = 0.0
        
        if let currentUserID = currentUserID, let myState = participantStates.first(where: { $0.userID == currentUserID }) {
            myEtaMinutes = myState.etaMinutes ?? 0
            myDistanceKm = myState.distanceKm
        }

        guard let selected = select(from: participantStates) else {
            // Zero participants reporting yet or everyone has arrived
            let statusMessage = arrivedCount > 0 ? "Everyone has arrived" : "Waiting for location updates"
            return OmaweWidgetAttributes.ContentState(
                statusMessage: statusMessage,
                myEtaMinutes: myEtaMinutes,
                myDistanceKm: myDistanceKm,
                arrivedCount: arrivedCount,
                mates: mates
            )
        }

        let name = displayNames[selected.userID] ?? "Someone"

        return OmaweWidgetAttributes.ContentState(
            statusMessage: message(for: selected, name: name),
            myEtaMinutes: myEtaMinutes,
            myDistanceKm: myDistanceKm,
            arrivedCount: arrivedCount,
            mates: mates
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
