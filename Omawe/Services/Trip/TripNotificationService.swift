//
//  TripNotificationService.swift
//  Omawe
//

import UserNotifications
import CloudKit

/// TRIP-4: derives arrival/delay/nearby notifications from ETA-2's already-
/// computed `ParticipantTripStatus` transitions rather than a separate
/// CloudKit subscription or threshold check — keeping `ParticipantStatusEngine`
/// (AD-6) the single source of truth for what counts as "delayed"/"near", per
/// the ticket's recommendation. The underlying data still arrives via LOC-1's
/// existing silent-push → `TripStatusViewModel.refresh()` path; this service
/// only reacts to the result, it doesn't add a second push pipeline.
/// Thin seam around `UNUserNotificationCenter.add(_:withCompletionHandler:)`
/// so `TripNotificationService`'s trigger-derivation/hysteresis logic can be
/// unit-tested against a fake, without touching the real notification center.
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

    /// `cooldown` default (5 min) guards against AD-6's near-destination
    /// boundary flapping (1km/3min) re-firing the same notification on every
    /// poll tick while a participant hovers right at the threshold.
    init(
        center: NotificationScheduling = UNUserNotificationCenter.current(),
        cooldown: TimeInterval = 300,
        now: @escaping () -> Date = { Date() }
    ) {
        self.center = center
        self.cooldown = cooldown
        self.now = now
    }

    /// Diffs `previous` against `updated` per participant and schedules a
    /// local notification for any *other* participant's transition into
    /// `.arrived`/`.delayed`/`.nearDestination` — never for `currentUserID`'s
    /// own status, since a device doesn't need to be told about itself.
    func notifyTransitions(
        previous: [CKRecord.ID: ParticipantTripState],
        updated: [CKRecord.ID: ParticipantTripState],
        displayNames: [CKRecord.ID: String],
        currentUserID: CKRecord.ID
    ) {
        for (userID, state) in updated where userID != currentUserID {
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
        // on authorization status here by design (TRIP-4: denial degrades
        // silently, not an error state).
        center.add(request, withCompletionHandler: nil)
    }
}

/// The subset of `ParticipantTripStatus` this ticket notifies on. `.onTheWay`
/// and `.offline` are not user-facing notification triggers per TRIP-4's
/// objective (arrival/delay/nearby only). Copy is confirmed-pending-product
/// per the ticket's own note ("confirm copy with whoever owns product copy")
/// — these strings are this engineering pass's placeholder, not final UX copy.
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

    // Status-derived copy only — no raw coordinates, consistent with LOC-1's
    // guidance on not exposing precise location outside the sync path.
    func body(name: String) -> String {
        switch self {
        case .arrived: return "\(name) has arrived."
        case .delayed: return "\(name) is running behind schedule."
        case .nearby: return "\(name) is almost at the destination."
        }
    }
}
