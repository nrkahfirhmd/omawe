import Foundation

/// Denied/restricted gets a Settings deep-link prompt; reduced accuracy gets
/// a lighter notice; fully authorized shows nothing.
enum PermissionDisplayState: Equatable {
    case none
    case deniedOrRestricted
    case reducedAccuracy

    static func from(_ authorization: LocationAuthorizationState) -> PermissionDisplayState {
        switch authorization {
        case .denied, .restricted:
            return .deniedOrRestricted
        case .authorizedReducedAccuracy:
            return .reducedAccuracy
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            return .none
        }
    }
}

/// "stale" ("we knew, but it's old") and "unavailable" ("we don't know
/// where they are") stay distinct instead of one generic "no location" state.
enum ParticipantLocationDisplayState: Equatable {
    case normal
    case stale(lastUpdated: Date)
    case unavailable

    static func from(
        hasEverReceivedLocation: Bool,
        isStale: Bool,
        lastUpdated: Date?
    ) -> ParticipantLocationDisplayState {
        guard hasEverReceivedLocation, let lastUpdated else { return .unavailable }
        return isStale ? .stale(lastUpdated: lastUpdated) : .normal
    }
}

final class StaleDisplayDebouncer {
    private let minimumDwell: TimeInterval
    private let now: () -> Date
    private var displayed: ParticipantLocationDisplayState?
    private var lastFlipAt: Date?

    init(minimumDwell: TimeInterval = 5, now: @escaping () -> Date = { Date() }) {
        self.minimumDwell = minimumDwell
        self.now = now
    }

    func display(for raw: ParticipantLocationDisplayState) -> ParticipantLocationDisplayState {
        guard let displayed else {
            accept(raw)
            return raw
        }

        if isUnavailable(raw) || isUnavailable(displayed) {
            accept(raw)
            return raw
        }

        if sameBucket(displayed, raw) {
            self.displayed = raw // refresh e.g. the "stale since" timestamp even though the bucket is unchanged
            return raw
        }

        guard let lastFlipAt, now().timeIntervalSince(lastFlipAt) >= minimumDwell else {
            return displayed // too soon since the last flip — hold what's already shown
        }

        accept(raw)
        return raw
    }

    private func accept(_ state: ParticipantLocationDisplayState) {
        displayed = state
        lastFlipAt = now()
    }

    private func isUnavailable(_ state: ParticipantLocationDisplayState) -> Bool {
        if case .unavailable = state { return true }
        return false
    }

    private func sameBucket(_ lhs: ParticipantLocationDisplayState, _ rhs: ParticipantLocationDisplayState) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal), (.stale, .stale):
            return true
        default:
            return false
        }
    }
}
