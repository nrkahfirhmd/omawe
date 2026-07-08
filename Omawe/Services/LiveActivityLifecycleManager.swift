//
//  LiveActivityLifecycleManager.swift
//  Omawe
//

import ActivityKit
import Foundation

/// Seam around `Activity<OmaweWidgetAttributes>` so ETA-4's lifecycle
/// transition logic (start/update/end triggers, throttling) can be
/// unit-tested against a fake — the real ActivityKit behavior (push-token
/// delivery, system budget limits, real device rendering) is explicitly not
/// Simulator-testable and needs the mandatory on-device manual test.
protocol LiveActivityControlling {
    func start(attributes: OmaweWidgetAttributes, content: OmaweWidgetAttributes.ContentState) throws
    func update(content: OmaweWidgetAttributes.ContentState) async
    func end(content: OmaweWidgetAttributes.ContentState) async
}

final class ActivityKitLiveActivityController: LiveActivityControlling {
    private var activity: Activity<OmaweWidgetAttributes>?

    func start(attributes: OmaweWidgetAttributes, content: OmaweWidgetAttributes.ContentState) throws {
        activity = try Activity.request(
            attributes: attributes,
            content: .init(state: content, staleDate: nil)
        )
    }

    func update(content: OmaweWidgetAttributes.ContentState) async {
        guard let activity else { return }
        await activity.update(.init(state: content, staleDate: nil))
    }

    func end(content: OmaweWidgetAttributes.ContentState) async {
        guard let activity else { return }
        await activity.end(.init(state: content, staleDate: nil), dismissalPolicy: .immediate)
        self.activity = nil
    }
}

/// Orchestrates the Live Activity's lifecycle: start on trip-start, update
/// on meaningful `ContentState` changes (not every refresh tick), end on
/// trip-end. `Activity.request` failures (Live Activities disabled in
/// Settings, concurrent-activity limit reached) are handled as soft
/// failures — in-app trip status must keep working even if the Live
/// Activity never starts.
@Observable
final class LiveActivityLifecycleManager {
    private let controller: LiveActivityControlling
    private(set) var isActive = false
    private var lastContent: OmaweWidgetAttributes.ContentState?

    private(set) var lastErrorMessage: String?

    init(controller: LiveActivityControlling = ActivityKitLiveActivityController()) {
        self.controller = controller
    }

    func start(attributes: OmaweWidgetAttributes, initialContent: OmaweWidgetAttributes.ContentState) {
        guard !isActive else { return }
        do {
            try controller.start(attributes: attributes, content: initialContent)
            isActive = true
            lastContent = initialContent
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = ErrorHelper.simplify(error)
            isActive = false
        }
    }

    /// Skips the call entirely when `content` hasn't meaningfully changed —
    /// ETA-3's aggregation can run on every refresh tick, but ActivityKit's
    /// update budget means not every tick can become an `.update` call.
    func update(_ content: OmaweWidgetAttributes.ContentState) async {
        guard isActive, content != lastContent else { return }
        await controller.update(content: content)
        lastContent = content
    }

    /// System-initiated end (user dismissed it, or it hit ActivityKit's own
    /// timeout) is treated the same as an app-initiated end — not fought.
    func end(_ content: OmaweWidgetAttributes.ContentState) async {
        guard isActive else { return }
        await controller.end(content: content)
        isActive = false
        lastContent = nil
    }
}
