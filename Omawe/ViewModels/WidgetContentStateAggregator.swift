import CloudKit

/// Reshapes per-participant ETA-2 states into the widget's single
/// `statusMessage`. No product-confirmed policy exists for which
/// participant "wins" (ETA-3's "Confirmed ambiguity") — this picks whoever
/// is furthest from arrival as an engineering default; flag for product
/// review before shipping.
enum WidgetContentStateAggregator {

    /// - Parameters:
    ///   - participantStates: One state per participant currently reporting
    ///     a location (ETA-1/ETA-2 output).
    ///   - displayNames: Participant display names for the third-person
    ///     `statusMessage` copy (e.g. "Bintang is on the way").
    static func aggregate(
        participantStates: [ParticipantTripState],
        displayNames: [CKRecord.ID: String],
        trackScaleKm: Double,
        currentUserID: CKRecord.ID? = nil
    ) -> OmaweWidgetAttributes.ContentState {
        let arrivedCount = participantStates.count { $0.status == .arrived }
        
        let mates = displayNames.map { (userID, name) -> OmaweWidgetAttributes.MateProgress in
            let initial = String(name.prefix(1)).uppercased()
            let isMe = userID == currentUserID
            let state = participantStates.first { $0.userID == userID }
            
            let distanceKm = state?.distanceKm ?? trackScaleKm
            var progress = 0.0
            
            if trackScaleKm > 0 {
                progress = 1.0 - (distanceKm / trackScaleKm)
            }
            if state?.status == .arrived || distanceKm <= 0 {
                progress = 1.0
            }
            // clamp
            progress = max(0.0, min(1.0, progress))
            
            return OmaweWidgetAttributes.MateProgress(
                label: initial,
                distanceKm: distanceKm,
                progress: progress,
                isMe: isMe,
                isLate: state?.status == .delayed
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
                mates: mates,
                trackScaleKm: trackScaleKm
            )
        }

        let name = displayNames[selected.userID] ?? "Someone"

        return OmaweWidgetAttributes.ContentState(
            statusMessage: message(for: selected, name: name),
            myEtaMinutes: myEtaMinutes,
            myDistanceKm: myDistanceKm,
            arrivedCount: arrivedCount,
            mates: mates,
            trackScaleKm: trackScaleKm
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
