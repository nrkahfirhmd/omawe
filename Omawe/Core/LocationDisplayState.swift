//
//  LocationDisplayState.swift
//  Omawe
//

import Foundation

/// NFR-1: the current device's own permission-related banner state, derived
/// from LOC-2's richer `LocationAuthorizationState` — denied/restricted gets
/// a Settings deep-link prompt; reduced accuracy gets a lighter "approximate
/// location" notice; anything already fully authorized shows nothing. Pure
/// function so it's unit-testable without a UI harness.
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

/// NFR-1: which of the three per-participant location states a map pin or
/// roster entry should show. Kept visually and semantically distinct per the
/// ticket — "stale" reads as "we knew, but it's old"; "unavailable" reads as
/// "we don't know where they are" — rather than collapsing both into one
/// generic "no location" treatment.
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

/// UI-layer hysteresis for `ParticipantLocationDisplayState` flicker right at
/// LOC-1's 30s staleness boundary — distinct from ETA-2's own status-
/// transition hysteresis, a different concern at a different layer, per the
/// ticket. Holds the previously-displayed stale/normal bucket for at least
/// `minimumDwell` before accepting a flip between them. `.unavailable` is
/// never held back — a participant either has data or doesn't, there's no
/// boundary to flicker across, so that transition is always immediate.
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
