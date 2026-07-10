import CoreLocation
import SwiftUI
import Combine

final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var locationGranted = false
    @Published var backgroundGranted = false

    override init() {
        super.init()

        manager.delegate = self
        refreshStatus()
    }

    func refreshStatus() {
        let status = manager.authorizationStatus

        locationGranted =
            status == .authorizedWhenInUse ||
            status == .authorizedAlways

        backgroundGranted =
            status == .authorizedAlways
    }

    func requestPermissions() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        refreshStatus()

        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
}
