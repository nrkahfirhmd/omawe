//
//  DebugLog.swift
//  Omawe
//

import Foundation

/// Drop-in replacement for the codebase's pre-existing `print()`-based debug
/// logging (`CloudKitTripService`, `CloudKitSharingService`, `HomeViewModel`,
/// etc.) — same call signature, but compiled out of Release builds instead
/// of shipping to production logs. NFR-2 requires existing debug output be
/// "removed or gated behind a debug-only flag, not left mixed with
/// production instrumentation" (see `AnalyticsService`, which owns the real
/// production events); this is that gate.
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let message = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(message, terminator: terminator)
    #endif
}
