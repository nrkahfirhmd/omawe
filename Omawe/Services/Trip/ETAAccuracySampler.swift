import CloudKit

/// compares the most recent ETA predicted while a participant was still en route against how long arrival
/// actually took, logging the delta via `AnalyticsLogging`.
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
    /// from before and after that refresh.
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
