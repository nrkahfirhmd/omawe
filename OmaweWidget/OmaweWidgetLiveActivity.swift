//
//  OmaweWidgetLiveActivity.swift
//  OmaweWidget
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

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
                                value: context.state.myEtaMinutes,
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
                            let km = context.state.myDistanceKm
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
                    ZStack {
                        PolkaDotBackground(
                            dotSize: 3,
                            spacing: 10,
                            color: Color(red: 0.01, green: 0.78, blue: 0.70).opacity(1) // LATheme.teal
                        )
                        .offset(y: -15)
                        
                        .mask {
                            Ellipse()
                                .padding(.horizontal, 20)
                                .blur(radius: 50)
                                .scaleEffect(x: 1, y: 0.35)
                                .offset(y: -30)
                        }
                        
//                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        
                        VStack(spacing: 8) {
                            // Route progress with mate markers
                            RouteProgressView(
                                mates: context.state.mates
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
                }
            }  compactLeading: {
                // Compact Left: People icon + ETA
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                    Text("\(context.state.myEtaMinutes)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.tertiary)
                }
            } compactTrailing: {
                // Compact Right: Distance
                Text("\(Int(context.state.myDistanceKm))km")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.tertiary)
            } minimal: {
                // Minimal: People icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.tertiary)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(context.state.myDistanceKm <= 0.5 ? Theme.tertiaryBox : .orange)
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
            myEtaMinutes: 12,
            myDistanceKm: 15.0,
            arrivedCount: 2,
            mates: [
                OmaweWidgetAttributes.MateProgress(label: "B", distanceKm: 15.0, isMe: false),
                OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 10.0, isMe: true)
            ]
        )
    }
    
    fileprivate static var almostThere: OmaweWidgetAttributes.ContentState {
        OmaweWidgetAttributes.ContentState(
            statusMessage: "Kahfi is arriving now!",
            myEtaMinutes: 2,
            myDistanceKm: 2.5,
            arrivedCount: 4,
            mates: [
                OmaweWidgetAttributes.MateProgress(label: "K", distanceKm: 0.5, isMe: false),
                OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 2.5, isMe: true)
            ]
        )
    }
}

#Preview("Notification", as: .content, using: OmaweWidgetAttributes.preview) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState.onTheWay
    OmaweWidgetAttributes.ContentState.almostThere
}


#Preview("Dynamic Island - 6 Mates (Expanded)", as: .dynamicIsland(.expanded), using: OmaweWidgetAttributes(
    tripName: "Bali Road Trip",
    destinationName: "Uluwatu Temple",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Everyone is on the move",
        myEtaMinutes: 20,
        myDistanceKm: 10.0,
        arrivedCount: 0,
        mates: [
            OmaweWidgetAttributes.MateProgress(label: "B", distanceKm: 15.0, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "K", distanceKm: 14.8, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 10.0, isMe: true),
            OmaweWidgetAttributes.MateProgress(label: "A", distanceKm: 9, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "C", distanceKm: 0.2, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "D", distanceKm: 0.1, isMe: false)
        ]
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
        myEtaMinutes: 12,
        myDistanceKm: 15.0, // Orange border
        arrivedCount: 2,
        mates: []
    )
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Arrived",
        myEtaMinutes: 0,
        myDistanceKm: 0.2, // Green border
        arrivedCount: 6,
        mates: []
    )
}
