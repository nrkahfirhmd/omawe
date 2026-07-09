//
//  OmaweWidgetAttributes.swift
//  Shared
//
//  Shared between the "Omawe" app target (which starts/updates/ends the
//  Activity, ETA-4) and "OmaweWidgetExtension" (which renders it) — an
//  ActivityAttributes type must be visible to both sides of the Live
//  Activity, so this file lives in a folder synchronized into both targets
//  rather than under either Omawe/ or OmaweWidget/ alone.
//

import ActivityKit

struct OmaweWidgetAttributes: ActivityAttributes {
    public struct MateProgress: Codable, Hashable {
        var label: String
        var distanceKm: Double
        var progress: Double = 0.0 // 0.0 to 1.0
        var isMe: Bool
    }

    public struct ContentState: Codable, Hashable {
        var statusMessage: String   // e.g. "Bintang is on the way"
        var myEtaMinutes: Int       // Current user's ETA
        var myDistanceKm: Double    // Current user's Distance
        var arrivedCount: Int       // e.g. 3
        var mates: [MateProgress]   // List of all participants (including current user)
        var trackScaleKm: Double = 0.0 // Fixed absolute max distance for UI scaling
    }

    // Fixed non-changing properties
    var tripName: String
    var destinationName: String
    var totalMates: Int
}
