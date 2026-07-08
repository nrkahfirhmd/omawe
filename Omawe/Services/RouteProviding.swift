//
//  RouteProviding.swift
//  Omawe
//

import CoreLocation
import MapKit

struct RouteResult: Equatable {
    let etaSeconds: TimeInterval
    let distanceMeters: CLLocationDistance
    /// NFR-4: carries the actual route geometry so a map view can draw the
    /// same polyline ETA-1 already computed here, instead of issuing a
    /// second, redundant `MKDirections` request for the same origin/
    /// destination — that would double this feature's exposure to Apple's
    /// rate limit for no benefit. `nil` for fakes/tests that only care about
    /// the numeric eta/distance.
    let route: MKRoute?

    init(etaSeconds: TimeInterval, distanceMeters: CLLocationDistance, route: MKRoute? = nil) {
        self.etaSeconds = etaSeconds
        self.distanceMeters = distanceMeters
        self.route = route
    }

    // `MKRoute` isn't `Equatable` — route identity was never part of this
    // struct's value semantics for existing callers (ETA-1's fallback/cache
    // comparisons only ever cared about eta/distance), so it's excluded here
    // rather than blocking synthesis for everyone.
    static func == (lhs: RouteResult, rhs: RouteResult) -> Bool {
        lhs.etaSeconds == rhs.etaSeconds && lhs.distanceMeters == rhs.distanceMeters
    }
}

enum RouteProvidingError: Error {
    case noRouteFound
}

/// Seam around `MKDirections` so ETA-1's fallback-selection logic can be
/// unit-tested against a fake — real `MKDirections` needs network + the
/// Apple Maps backend and can't run in a unit test target.
protocol RouteProviding {
    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteResult
}

struct MKDirectionsRouteProvider: RouteProviding {
    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: origin.latitude, longitude: origin.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
        request.transportType = .automobile

        let response = try await MKDirections(request: request).calculate()

        guard let route = response.routes.first else {
            throw RouteProvidingError.noRouteFound
        }

        return RouteResult(etaSeconds: route.expectedTravelTime, distanceMeters: route.distance, route: route)
    }
}
