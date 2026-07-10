import CoreLocation

/// The four states the UI/widget consume, plus `.arrived`
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
    let reportedLateAt: Date?
    let etaAtLastOnTheWay: TimeInterval?
    let now: Date
}

enum ParticipantStatusEngine {
    static let arrivedDistanceMeters: CLLocationDistance = 100

    /// Precedence: offline > arrived > delayed > nearDestination > onTheWay.
    /// Offline wins because a stale "arrived"/"near" reading is misleading.
    static func status(for input: ParticipantStatusInput) -> ParticipantTripStatus {
        if LocationCore.isOffline(lastUpdate: input.lastUpdate, isBackgrounded: input.isBackgrounded, now: input.now) {
            return .offline
        }

        if let reportedLateAt = input.reportedLateAt, input.now.timeIntervalSince(reportedLateAt) < 300 {
            return .delayed
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

/// Owns the "ETA at last on-the-way" baseline. First update seeds the
/// baseline and defaults to `.onTheWay` rather than risking a false
/// "delayed" reading with nothing to compare against yet.
final class ParticipantStatusTracker {
    private var etaAtLastOnTheWay: TimeInterval?
    private var isFirstUpdate = true
    private(set) var currentStatus: ParticipantTripStatus = .onTheWay

    func update(
        distanceMeters: CLLocationDistance,
        etaMinutes: Int?,
        lastUpdate: Date,
        isBackgrounded: Bool,
        reportedLateAt: Date? = nil,
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
            reportedLateAt: reportedLateAt,
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
