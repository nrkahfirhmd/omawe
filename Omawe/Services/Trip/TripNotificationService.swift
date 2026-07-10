import UserNotifications
import CloudKit

protocol NotificationScheduling {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
}

extension UNUserNotificationCenter: NotificationScheduling {}

final class TripNotificationService {
    private let center: NotificationScheduling
    private var lastNotifiedStatus: [CKRecord.ID: ParticipantTripStatus] = [:]
    private var lastNotifiedAt: [CKRecord.ID: Date] = [:]
    private let cooldown: TimeInterval
    private let now: () -> Date

    /// `cooldown` default (30s) guards against near-destination boundary
    /// flapping re-firing the same notification every poll tick.
    init(
        center: NotificationScheduling = UNUserNotificationCenter.current(),
        cooldown: TimeInterval = 30,
        now: @escaping () -> Date = { Date() }
    ) {
        self.center = center
        self.cooldown = cooldown
        self.now = now
    }

    /// Notifies on any *other* participant's transition into arrived/delayed/
    /// nearDestination — never for `currentUserID`'s own status.
    func notifyTransitions(
        previous: [CKRecord.ID: ParticipantTripState],
        updated: [CKRecord.ID: ParticipantTripState],
        displayNames: [CKRecord.ID: String],
        currentUserID: CKRecord.ID
    ) {
        for (userID, state) in updated {
            guard let transition = NotifiableTransition(status: state.status) else { continue }
            guard previous[userID]?.status != state.status else { continue }

            if let lastStatus = lastNotifiedStatus[userID],
               lastStatus == state.status,
               let lastAt = lastNotifiedAt[userID],
               now().timeIntervalSince(lastAt) < cooldown {
                continue
            }

            schedule(transition, for: userID, name: displayNames[userID] ?? "Your travel companion")
            lastNotifiedStatus[userID] = state.status
            lastNotifiedAt[userID] = now()
        }
    }

    private func schedule(_ transition: NotifiableTransition, for userID: CKRecord.ID, name: String) {
        let content = UNMutableNotificationContent()
        content.title = transition.title
        content.body = transition.body(name: name)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "trip-status-\(userID.recordName)-\(transition.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        // Silently does nothing if the user denied permission — no branching
        // on authorization status here by design
        center.add(request, withCompletionHandler: nil)
    }
}

private enum NotifiableTransition: String {
    case arrived
    case delayed
    case nearby

    init?(status: ParticipantTripStatus) {
        switch status {
        case .arrived: self = .arrived
        case .delayed: self = .delayed
        case .nearDestination: self = .nearby
        case .onTheWay, .offline: return nil
        }
    }

    var title: String {
        switch self {
        case .arrived: return "Arrived"
        case .delayed: return "Running late"
        case .nearby: return "Almost there"
        }
    }

    // Status-derived copy only — no raw coordinates, consistent with
    // guidance on not exposing precise location outside the sync path.
    func body(name: String) -> String {
        switch self {
        case .arrived: return "\(name) has arrived."
        case .delayed: return "\(name) is running behind schedule."
        case .nearby: return "\(name) is almost at the destination."
        }
    }
}
