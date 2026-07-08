//
//  ETAAccuracySampler.swift
//  Omawe
//

import CloudKit

/// NFR-2's "ETA accuracy sampling" metric: compares the most recent ETA
/// predicted while a participant was still en route against how long arrival
/// actually took, logging the delta via `AnalyticsLogging`.
///
/// Keeps its own baseline rather than reaching into
/// `ParticipantStatusTracker`'s private `etaAtLastOnTheWay` (ETA-2, already
/// shipped/tested) — same "last known ETA before arrival" concept, kept as a
/// separate, independently testable sampler instead of modifying ETA-2's
/// internals for this ticket's sake.
final class ETAAccuracySampler {
    private struct Baseline {
        let etaSeconds: TimeInterval
        let capturedAt: Date
    }

    private var baselines: [CKRecord.ID: Baseline] = [:]
    private let analytics: AnalyticsLogging
    private let now: () -> Date

    init(analytics: AnalyticsLogging = AnalyticsService.shared, now: @escaping () -> Date = { Date() }) {
        self.analytics = analytics
        self.now = now
    }

    /// Call once per `TripStatusViewModel.refresh()` tick with the states
    /// from before and after that refresh. Logs one sample per participant
    /// the instant they transition into `.arrived`, using whatever ETA
    /// prediction was most recently captured for them while en route.
    func recordTransitions(
        previous: [CKRecord.ID: ParticipantTripState],
        updated: [CKRecord.ID: ParticipantTripState]
    ) {
        for (userID, state) in updated {
            let justArrived = state.status == .arrived && previous[userID]?.status != .arrived

            if justArrived {
                if let baseline = baselines[userID] {
                    analytics.log(.etaAccuracySample(
                        predictedSeconds: baseline.etaSeconds,
                        actualSeconds: now().timeIntervalSince(baseline.capturedAt)
                    ))
                }
                baselines[userID] = nil
            } else if state.status != .arrived, !state.isStale, let etaMinutes = state.etaMinutes {
                baselines[userID] = Baseline(etaSeconds: TimeInterval(etaMinutes * 60), capturedAt: now())
            }
        }
    }
}
