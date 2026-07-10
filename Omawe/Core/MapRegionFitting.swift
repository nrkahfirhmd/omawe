import MapKit

/// pure region-fit calculation, independent of `Map` rendering
enum MapRegionFitting {
    /// Excludes "null island" (0,0) and non-finite/out-of-range coordinates —
    /// almost-certainly bad data from a GPS cold-start or parsing failure.
    static func isPlausible(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard coordinate.latitude.isFinite, coordinate.longitude.isFinite else { return false }
        guard abs(coordinate.latitude) > 0.0001 || abs(coordinate.longitude) > 0.0001 else { return false }
        return abs(coordinate.latitude) <= 90 && abs(coordinate.longitude) <= 180
    }

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
