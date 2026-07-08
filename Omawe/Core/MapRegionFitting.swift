//
//  MapRegionFitting.swift
//  Omawe
//

import MapKit

/// NFR-4: pure region-fit calculation, independent of `Map` rendering so
/// it's unit-testable without a UI harness.
enum MapRegionFitting {
    /// Excludes "null island" (0,0) and any non-finite/out-of-range
    /// coordinate as almost-certainly bad data (GPS cold-start or parsing
    /// failure) — the same guard LOC-5 uses — so a single bad coordinate
    /// can't blow the fitted region out to cover most of the globe.
    static func isPlausible(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard coordinate.latitude.isFinite, coordinate.longitude.isFinite else { return false }
        guard abs(coordinate.latitude) > 0.0001 || abs(coordinate.longitude) > 0.0001 else { return false }
        return abs(coordinate.latitude) <= 90 && abs(coordinate.longitude) <= 180
    }

    /// Smallest region covering every plausible coordinate in `coordinates`,
    /// padded so pins aren't flush against the map's edge and floored to a
    /// sane minimum span so a single point (or a tight cluster) still gets a
    /// sensible zoom level instead of a degenerate zero-size region. Returns
    /// nil if there are no plausible coordinates — callers should fall back
    /// to a default region rather than call this with an empty set.
    static func fitRegion(
        coordinates: [CLLocationCoordinate2D],
        paddingFactor: Double = 1.4,
        minimumSpanDegrees: Double = 0.01
    ) -> MKCoordinateRegion? {
        let plausible = coordinates.filter(isPlausible)
        guard !plausible.isEmpty else { return nil }

        let latitudes = plausible.map(\.latitude)
        let longitudes = plausible.map(\.longitude)

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * paddingFactor, minimumSpanDegrees),
            longitudeDelta: max((maxLon - minLon) * paddingFactor, minimumSpanDegrees)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
