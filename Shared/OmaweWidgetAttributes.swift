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
