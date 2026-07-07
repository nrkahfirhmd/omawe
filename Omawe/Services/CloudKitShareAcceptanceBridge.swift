//
//  CloudKitShareAcceptanceBridge.swift
//  Omawe
//
//  Created by Codex on 06/07/26.
//

import CloudKit
import UIKit

enum CloudKitShareAcceptanceBridge {
    static let notificationName = Notification.Name("CloudKitShareAcceptanceBridge.didReceiveMetadata")
    private static var pendingMetadata: [CKShare.Metadata] = []

    static func post(metadata: CKShare.Metadata) {
        pendingMetadata.append(metadata)
        NotificationCenter.default.post(name: notificationName, object: metadata)
    }

    static func metadata(from notification: Notification) -> CKShare.Metadata? {
        notification.object as? CKShare.Metadata
    }

    static func drainPendingMetadata() -> [CKShare.Metadata] {
        let metadata = pendingMetadata
        pendingMetadata.removeAll()
        return metadata
    }
}

/// Posted when a silent push delivers a CloudKit zone-change notification
/// for location updates, so any active trip screen can refresh without this
/// bridge needing a direct reference to LOC-2/ETA-1's view models.
enum LocationUpdateNotificationBridge {
    static let notificationName = Notification.Name("LocationUpdateNotificationBridge.didReceiveNotification")

    static func post(zoneID: CKRecordZone.ID) {
        NotificationCenter.default.post(name: notificationName, object: zoneID)
    }
}

final class OmaweAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = CloudKitSharingSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("[Push] Registered for remote notifications")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] Failed to register for remote notifications:", error.localizedDescription)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        guard
            let queryNotification = notification as? CKQueryNotification,
            let zoneID = queryNotification.recordID?.zoneID
        else {
            completionHandler(.noData)
            return
        }

        LocationUpdateNotificationBridge.post(zoneID: zoneID)
        completionHandler(.newData)
    }
}

final class CloudKitSharingSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            CloudKitShareAcceptanceBridge.post(metadata: metadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        CloudKitShareAcceptanceBridge.post(metadata: cloudKitShareMetadata)
    }
}
