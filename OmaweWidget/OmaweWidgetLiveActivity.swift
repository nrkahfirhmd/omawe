//
//  OmaweWidgetLiveActivity.swift
//  OmaweWidget
//
//  Created by Gleenryan on 29/06/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct OmaweWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct OmaweWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OmaweWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension OmaweWidgetAttributes {
    fileprivate static var preview: OmaweWidgetAttributes {
        OmaweWidgetAttributes(name: "World")
    }
}

extension OmaweWidgetAttributes.ContentState {
    fileprivate static var smiley: OmaweWidgetAttributes.ContentState {
        OmaweWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: OmaweWidgetAttributes.ContentState {
         OmaweWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: OmaweWidgetAttributes.preview) {
   OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState.smiley
    OmaweWidgetAttributes.ContentState.starEyes
}
