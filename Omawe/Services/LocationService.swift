import CoreLocation

/// Narrow surface of `CLLocationManager` so tests can inject a fake instead
/// of subclassing it (which isn't designed for that).
protocol CLLocationManagerRepresentable: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }

    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: CLLocationManagerRepresentable {}

/// Distinct published state for permission/accuracy, so NFR-1's UI can tell
/// "denied" and "reduced accuracy" apart from an ordinary lull in updates.
enum LocationAuthorizationState: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorizedReducedAccuracy
    case authorizedWhenInUse
    case authorizedAlways
}

protocol LocationServiceProtocol: AnyObject {
    var authorizationState: LocationAuthorizationState { get }
    var locationUpdates: AsyncStream<CLLocation> { get }

    func requestWhenInUseAuthorization()
    /// Only call this once the user has taken an action that implies they
    /// want background sharing (e.g. starting a trip) — never upfront.
    func requestAlwaysAuthorization()
    func startUpdating()
    func stopUpdating()
}

/// Deliberately has no CloudKit knowledge — `LocationSharingCoordinator`
/// bridges this to LOC-1's `CloudKitLocationSyncService`.
@Observable
final class LocationService: NSObject, LocationServiceProtocol {
    private let manager: CLLocationManagerRepresentable
    private var continuation: AsyncStream<CLLocation>.Continuation?

    let locationUpdates: AsyncStream<CLLocation>
    private(set) var authorizationState: LocationAuthorizationState

    init(manager: CLLocationManagerRepresentable = CLLocationManager()) {
        self.manager = manager
        self.authorizationState = Self.state(
            authorization: manager.authorizationStatus,
            accuracy: manager.accuracyAuthorization
        )

        var streamContinuation: AsyncStream<CLLocation>.Continuation!
        self.locationUpdates = AsyncStream { continuation in
            streamContinuation = continuation
        }

        super.init()

        self.continuation = streamContinuation

        // Tuned to LOC-1's 30s propagation budget, not maximum precision —
        // battery cost scales with accuracy/frequency and there's no
        // product requirement for sub-meter precision here.
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 25
        manager.delegate = self
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        if authorizationState == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    static func state(
        authorization: CLAuthorizationStatus,
        accuracy: CLAccuracyAuthorization
    ) -> LocationAuthorizationState {
        switch authorization {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorizedWhenInUse:
            return accuracy == .reducedAccuracy ? .authorizedReducedAccuracy : .authorizedWhenInUse
        case .authorizedAlways:
            return accuracy == .reducedAccuracy ? .authorizedReducedAccuracy : .authorizedAlways
        @unknown default:
            return .denied
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationState = Self.state(
            authorization: manager.authorizationStatus,
            accuracy: manager.accuracyAuthorization
        )
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        continuation?.yield(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // GPS signal loss (indoors/tunnels): don't tear the manager down —
        // let it keep reporting truthfully. LOC-1's `recordedAt` timestamp
        // is what lets NFR-1 detect staleness; this file doesn't own that UI.
    }
}
