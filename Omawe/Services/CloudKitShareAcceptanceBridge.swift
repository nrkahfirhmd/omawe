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

final class OmaweAppDelegate: NSObject, UIApplicationDelegate {
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
