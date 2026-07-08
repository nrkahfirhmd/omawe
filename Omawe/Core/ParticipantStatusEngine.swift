//
//  ParticipantStatusEngine.swift
//  Omawe
//

import CoreLocation

/// The four states the UI/widget consume (AD-6), plus `.arrived` — a
/// terminal state distinct from `.nearDestination` that the widget's
/// `arrivedCount` needs but AD-6 doesn't explicitly define. `arrivedDistanceMeters`
/// below is this ticket's own engineering default pending product confirmation
/// (see ETA-2's "Risks / open questions").
enum ParticipantTripStatus: String, Codable, Equatable {
    case onTheWay
    case nearDestination
    case delayed
    case offline
    case arrived
}

struct ParticipantStatusInput {
    let distanceMeters: CLLocationDistance
    let etaMinutes: Int?
    let lastUpdate: Date
    let isBackgrounded: Bool
    /// Nil only before the first-ever reading for a participant (see
    /// `ParticipantStatusTracker`, which owns and updates this across calls).
    let etaAtLastOnTheWay: TimeInterval?
    let now: Date
}

/// Pure derivation of `ParticipantTripStatus` from ETA-1's raw numbers via
/// `LocationCore`'s already-tested AD-6 predicates — this type never
/// reimplements a threshold value, only precedence between them.
enum ParticipantStatusEngine {

    static let arrivedDistanceMeters: CLLocationDistance = 100

    /// Precedence when multiple conditions could apply (highest to lowest):
    /// offline > arrived > delayed > nearDestination > onTheWay. Offline wins
    /// over everything else because a stale "arrived"/"near destination"
    /// reading is misleading if the device hasn't reported in over the
    /// offline threshold — AD-6 doesn't state this ordering explicitly, so
    /// it's a recommendation to confirm with product (see ETA-2 ticket).
    static func status(for input: ParticipantStatusInput) -> ParticipantTripStatus {
        if LocationCore.isOffline(lastUpdate: input.lastUpdate, isBackgrounded: input.isBackgrounded, now: input.now) {
            return .offline
        }

        if input.distanceMeters <= arrivedDistanceMeters {
            return .arrived
        }

        if let etaAtLastOnTheWay = input.etaAtLastOnTheWay, let etaMinutes = input.etaMinutes {
            let currentETASeconds = TimeInterval(etaMinutes * 60)
            if LocationCore.isDelayed(currentETA: currentETASeconds, etaAtLastOnTheWay: etaAtLastOnTheWay) {
                return .delayed
            }
        }

        if LocationCore.isNearDestination(distance: input.distanceMeters, etaMinutes: input.etaMinutes) {
            return .nearDestination
        }

        return .onTheWay
    }
}

/// Owns the "ETA at last on-the-way" baseline for a single participant
/// (ETA-2 step 2) — this is state that has to persist and mutate across
/// successive readings, not something derivable from one point-in-time
/// sample. Also owns the first-update edge case: with no baseline yet,
/// default to `.onTheWay` using the first ETA as the baseline, rather than
/// risking a false "delayed" reading on the very first sample.
final class ParticipantStatusTracker {
    private var etaAtLastOnTheWay: TimeInterval?
    private var isFirstUpdate = true
    private(set) var currentStatus: ParticipantTripStatus = .onTheWay

    func update(
        distanceMeters: CLLocationDistance,
        etaMinutes: Int?,
        lastUpdate: Date,
        isBackgrounded: Bool,
        now: Date = Date()
    ) -> ParticipantTripStatus {
        if isFirstUpdate {
            isFirstUpdate = false
            if let etaMinutes {
                etaAtLastOnTheWay = TimeInterval(etaMinutes * 60)
            }
            currentStatus = .onTheWay
        }

        let status = ParticipantStatusEngine.status(for: ParticipantStatusInput(
            distanceMeters: distanceMeters,
            etaMinutes: etaMinutes,
            lastUpdate: lastUpdate,
            isBackgrounded: isBackgrounded,
            etaAtLastOnTheWay: etaAtLastOnTheWay,
            now: now
        ))

        if status == .onTheWay, let etaMinutes {
            etaAtLastOnTheWay = TimeInterval(etaMinutes * 60)
        }

        currentStatus = status
        return status
    }
}
