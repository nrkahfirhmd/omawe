import CoreLocation

/// Pure, synchronous distance/ETA threshold math.
/// No CloudKit, no CLLocationManager, no MapKit — keep it dependency-free and testable without mocks.
enum LocationCore {
    // MARK: - thresholds
    static let nearDestinationDistanceMeters: CLLocationDistance = 1_000
    static let nearDestinationETAMinutes: Int = 3
    static let delayedETAThresholdSeconds: TimeInterval = 10 * 60
    static let offlineBackgroundedThresholdSeconds: TimeInterval = 2 * 60
    static let offlineForegroundedThresholdSeconds: TimeInterval = 30

    // MARK: - Distance
    static func straightLineDistance(from: Location, to: Location) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    // MARK: - Predicates
    /// Falls back to distance alone when `etaMinutes` is nil (e.g. `MKDirections` failed).
    static func isNearDestination(distance: CLLocationDistance, etaMinutes: Int?) -> Bool {
        if distance <= nearDestinationDistanceMeters {
            return true
        }
        guard let etaMinutes else {
            return false
        }
        return etaMinutes <= nearDestinationETAMinutes
    }

    static func isDelayed(currentETA: TimeInterval, etaAtLastOnTheWay: TimeInterval) -> Bool {
        currentETA - etaAtLastOnTheWay >= delayedETAThresholdSeconds
    }

    static func isOffline(lastUpdate: Date, isBackgrounded: Bool, now: Date = .now) -> Bool {
        let elapsed = now.timeIntervalSince(lastUpdate)
        let threshold = isBackgrounded ? offlineBackgroundedThresholdSeconds : offlineForegroundedThresholdSeconds
        return elapsed >= threshold
    }
}
