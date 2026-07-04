//
//  OmaweWidgetLiveActivity.swift
//  OmaweWidget
//
//  Created by Gleenryan on 29/06/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes Model
struct OmaweWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var statusMessage: String   // e.g. "Bintang is on the way"
        var etaMinutes: Int         // e.g. 15
        var arrivedCount: Int       // e.g. 3
        var distanceKm: Double      // e.g. 15.0
    }

    // Fixed non-changing properties
    var tripName: String
    var destinationName: String
    var totalMates: Int
}

// MARK: - Live Activity Config
struct OmaweWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OmaweWidgetAttributes.self) { context in
            // Lock screen / banner notification UI
            LiveActivityLockScreenView(context: context)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Leading (ETA)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ETA")
                            .font(.caption2)
                            .opacity(0.8)
                            .bold()
                            .foregroundStyle(.gray)
                        Text({
                            let eta = Calendar.current.date(
                                byAdding: .minute,
                                value: context.state.etaMinutes,
                                to: Date()
                            ) ?? Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            return formatter.string(from: eta)
                        }())
                        .font(.subheadline)
                        .fontWidth(.expanded)
                        .fontWeight(.semibold)
                        .foregroundStyle(.yellow)
                    }
//                    .padding(.top,20)
                    .padding(.leading, 10)
                }
                
                // Expanded UI - Trailing (Distance)
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Distance")
                            .font(.caption2)
                            .opacity(0.8)
                            .bold()
                            .foregroundStyle(.gray)
                        Text({
                            let km = context.state.distanceKm
                            if km >= 1 {
                                return "\(Int(km))km"
                            } else {
                                return "\(Int(km * 1000))m"
                            }
                        }())
                        .font(.subheadline)
                        .fontWidth(.expanded)
                        .fontWeight(.semibold)
                        .foregroundStyle(.yellow)
                    }
                    .padding(.trailing,10)
                }
                
                // Expanded UI - Bottom (Route + Alert/Report)
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Route progress with mate markers
                        RouteProgressView(
                            totalMates: context.attributes.totalMates,
                            arrivedCount: context.state.arrivedCount
                        )
                        .padding(.horizontal,10)
                        
                        // Alert icon + Report button
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 44, height: 44)
                            
                            Link(destination: URL(string: "omawe://report")!) {
                                HStack(spacing: 7) {
                                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Text("Report")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .fontWidth(.expanded)
                                        .foregroundStyle(.white)
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 10)
                }
            }  compactLeading: {
                // Compact Left: People icon + ETA
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.01, green: 0.78, blue: 0.70))
                    Text("\(context.state.etaMinutes)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            } compactTrailing: {
                // Compact Right: Distance
                Text("\(Int(context.state.distanceKm))km")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.01, green: 0.78, blue: 0.70))
            } minimal: {
                // Minimal: People icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 0.01, green: 0.78, blue: 0.70))
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color(red: 0.01, green: 0.78, blue: 0.70))
        }
    }
}

// MARK: - Previews
extension OmaweWidgetAttributes {
    fileprivate static var preview: OmaweWidgetAttributes {
        OmaweWidgetAttributes(
            tripName: "Ex-Boyfriends Celebration!",
            destinationName: "Toko Kopi Jaya, Kuta",
            totalMates: 6
        )
    }
}

extension OmaweWidgetAttributes.ContentState {
    fileprivate static var onTheWay: OmaweWidgetAttributes.ContentState {
        OmaweWidgetAttributes.ContentState(
            statusMessage: "Bintang is 5 mins away",
            etaMinutes: 12,
            arrivedCount: 2,
            distanceKm: 15.0
        )
    }
    
    fileprivate static var almostThere: OmaweWidgetAttributes.ContentState {
        OmaweWidgetAttributes.ContentState(
            statusMessage: "Kahfi is arriving now!",
            etaMinutes: 2,
            arrivedCount: 4,
            distanceKm: 2.5
        )
    }
}

#Preview("Notification", as: .content, using: OmaweWidgetAttributes.preview) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState.onTheWay
    OmaweWidgetAttributes.ContentState.almostThere
}


#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: OmaweWidgetAttributes(
    tripName: "Ex-Boyfriends Celebration!",
    destinationName: "Toko Kopi Jaya, Kuta",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Bintang is 5 mins away",
        etaMinutes: 12,
        arrivedCount: 2,
        distanceKm: 15.0
    )
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: OmaweWidgetAttributes(
    tripName: "Ex-Boyfriends Celebration!",
    destinationName: "Toko Kopi Jaya, Kuta",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Bintang is 5 mins away",
        etaMinutes: 12,
        arrivedCount: 2,
        distanceKm: 15.0
    )
}
