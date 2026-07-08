//
//  RouteProviding.swift
//  Omawe
//

import CoreLocation
import MapKit

struct RouteResult: Equatable {
    let etaSeconds: TimeInterval
    let distanceMeters: CLLocationDistance
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

        return RouteResult(etaSeconds: route.expectedTravelTime, distanceMeters: route.distance)
    }
}
