import XCTest
import MapKit
@testable import Omawe

final class MapRegionFittingTests: XCTestCase {

    func testIsPlausible_nullIsland_isNotPlausible() {
        XCTAssertFalse(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    }

    func testIsPlausible_nonFiniteCoordinate_isNotPlausible() {
        XCTAssertFalse(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: .nan, longitude: 10)))
        XCTAssertFalse(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: 10, longitude: .infinity)))
    }

    func testIsPlausible_outOfRangeCoordinate_isNotPlausible() {
        XCTAssertFalse(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: 95, longitude: 10)))
        XCTAssertFalse(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: 10, longitude: 190)))
    }

    func testIsPlausible_ordinaryCoordinate_isPlausible() {
        XCTAssertTrue(MapRegionFitting.isPlausible(CLLocationCoordinate2D(latitude: -8.748, longitude: 115.167)))
    }

    func testFitRegion_emptyInput_returnsNil() {
        XCTAssertNil(MapRegionFitting.fitRegion(coordinates: []))
    }

    func testFitRegion_onlyImplausibleCoordinates_returnsNil() {
        let region = MapRegionFitting.fitRegion(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: .nan, longitude: 5)
        ])
        XCTAssertNil(region)
    }

    func testFitRegion_singleCoordinate_returnsMinimumSpanNotZero() {
        let coordinate = CLLocationCoordinate2D(latitude: -8.748, longitude: 115.167)
        let region = MapRegionFitting.fitRegion(coordinates: [coordinate], minimumSpanDegrees: 0.02)

        XCTAssertNotNil(region)
        XCTAssertEqual(region?.center.latitude ?? 0, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(region?.span.latitudeDelta ?? 0, 0.02)
        XCTAssertEqual(region?.span.longitudeDelta ?? 0, 0.02)
    }

    func testFitRegion_multipleCoordinates_centersOnBoundingBoxMidpoint() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -8.70, longitude: 115.10),
            CLLocationCoordinate2D(latitude: -8.80, longitude: 115.20)
        ]
        let region = MapRegionFitting.fitRegion(coordinates: coordinates)

        XCTAssertEqual(region?.center.latitude ?? 0, -8.75, accuracy: 0.0001)
        XCTAssertEqual(region?.center.longitude ?? 0, 115.15, accuracy: 0.0001)
    }

    func testFitRegion_ignoresBadCoordinateAmongGoodOnes() {
        let good = [
            CLLocationCoordinate2D(latitude: -8.70, longitude: 115.10),
            CLLocationCoordinate2D(latitude: -8.80, longitude: 115.20)
        ]
        let withBadCoordinate = good + [CLLocationCoordinate2D(latitude: 0, longitude: 0)]

        let regionWithoutBad = MapRegionFitting.fitRegion(coordinates: good)
        let regionWithBad = MapRegionFitting.fitRegion(coordinates: withBadCoordinate)

        XCTAssertEqual(regionWithBad?.center.latitude ?? 0, regionWithoutBad?.center.latitude ?? 1, accuracy: 0.0001)
        XCTAssertEqual(regionWithBad?.span.latitudeDelta ?? 0, regionWithoutBad?.span.latitudeDelta ?? 1, accuracy: 0.0001)
    }

    func testFitRegion_paddingWidensSpanBeyondRawBoundingBox() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -8.70, longitude: 115.10),
            CLLocationCoordinate2D(latitude: -8.80, longitude: 115.20)
        ]
        let rawSpan = 0.10 // matches both lat/lon deltas above
        let region = MapRegionFitting.fitRegion(coordinates: coordinates, paddingFactor: 1.4, minimumSpanDegrees: 0)

        XCTAssertEqual(region?.span.latitudeDelta ?? 0, rawSpan * 1.4, accuracy: 0.0001)
    }
}
