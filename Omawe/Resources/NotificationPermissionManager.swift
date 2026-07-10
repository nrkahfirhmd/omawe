import UserNotifications
import SwiftUI
import Combine

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
