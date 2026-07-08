//
//  NotificationPermissionManager.swift
//  Omawe
//

import UserNotifications
import SwiftUI
import Combine

/// TRIP-4's notification permission — requested separately from
/// `LocationPermissionManager`'s location prompts, since these are a
/// distinct iOS permission with its own user-facing rationale (arrival/
/// delay/nearby alerts, not location tracking itself). A denial here is not
/// an error state: `requestPermissions()` is fire-and-forget and callers
/// never need to branch on its result — a denied/undetermined status just
/// means `UNUserNotificationCenter.add(_:)` silently does nothing later.
final class NotificationPermissionManager: NSObject, ObservableObject {
    private let center = UNUserNotificationCenter.current()

    @Published var isAuthorized = false

    override init() {
        super.init()
        refreshStatus()
    }

    func refreshStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestPermissions() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            self?.refreshStatus()
        }
    }
}
