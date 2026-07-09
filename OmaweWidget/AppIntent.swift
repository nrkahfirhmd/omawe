//
//  AppIntent.swift
//  OmaweWidget
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
//

import WidgetKit
import AppIntents
import CoreFoundation

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

@available(iOS 17.0, *)
struct ReportLateIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Report Late"
    
    func perform() async throws -> some IntentResult {
        // Send a Darwin notification to the main app to trigger the report instantly
        let name = CFNotificationName("com.exboyfriends.omawe.reportLate" as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), name, nil, nil, true)
        return .result()
    }
}
