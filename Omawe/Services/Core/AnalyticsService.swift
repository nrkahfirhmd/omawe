import Foundation
import os

/// `os.Logger` is dependency-free, ships in Release builds, and is queryable via Console.app/`log show`
/// — enough to give each metric "a concrete, firing instrumentation point"
enum AnalyticsEvent: Equatable {
    case tripCreateSucceeded(setupSeconds: TimeInterval)
    case tripCreateFailed(reason: String)
    case shareAcceptSucceeded(setupSeconds: TimeInterval)
    case shareAcceptFailed(reason: String)
    case liveActivityInteraction(kind: String)
    case etaAccuracySample(predictedSeconds: TimeInterval, actualSeconds: TimeInterval)
    case locationSyncResult(succeeded: Bool, attempts: Int)

    var name: String {
        switch self {
        case .tripCreateSucceeded: return "trip_create_succeeded"
        case .tripCreateFailed: return "trip_create_failed"
        case .shareAcceptSucceeded: return "share_accept_succeeded"
        case .shareAcceptFailed: return "share_accept_failed"
        case .liveActivityInteraction: return "live_activity_interaction"
        case .etaAccuracySample: return "eta_accuracy_sample"
        case .locationSyncResult: return "location_sync_result"
        }
    }

    /// Status-derived / numeric only — never raw coordinates
    var payload: String {
        switch self {
        case .tripCreateSucceeded(let seconds), .shareAcceptSucceeded(let seconds):
            return "setup_seconds=\(String(format: "%.2f", seconds))"
        case .tripCreateFailed(let reason), .shareAcceptFailed(let reason):
            return "reason=\(reason)"
        case .liveActivityInteraction(let kind):
            return "kind=\(kind)"
        case .etaAccuracySample(let predicted, let actual):
            return "predicted_seconds=\(Int(predicted)) actual_seconds=\(Int(actual)) delta_seconds=\(Int(actual - predicted))"
        case .locationSyncResult(let succeeded, let attempts):
            return "succeeded=\(succeeded) attempts=\(attempts)"
        }
    }
}

protocol AnalyticsLogging {
    func log(_ event: AnalyticsEvent)
}

/// Never throws, never blocks — an instrumentation failure must not be able
/// to fail the trip-creation/sync flow it's measuring
final class AnalyticsService: AnalyticsLogging {
    static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "com.exboyfriends.omaweapp", category: "analytics")

    func log(_ event: AnalyticsEvent) {
        logger.log("\(event.name, privacy: .public) \(event.payload, privacy: .public)")
    }
}
