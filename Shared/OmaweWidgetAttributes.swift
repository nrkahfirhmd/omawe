// Lives in Shared/, not Omawe/ or OmaweWidget/, because ActivityAttributes
// must be visible to both the app (starts/ends the Activity) and the widget extension (renders it).

import ActivityKit

struct OmaweWidgetAttributes: ActivityAttributes {
    public struct MateProgress: Codable, Hashable {
        var label: String
        var distanceKm: Double
        var progress: Double = 0.0 // 0.0 to 1.0
        var isMe: Bool
        var isLate: Bool = false
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
