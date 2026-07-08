//
//  LocationDisplayStateTests.swift
//  OmaweTests
//

import XCTest
@testable import Omawe

final class PermissionDisplayStateTests: XCTestCase {
    func testFrom_deniedOrRestricted_mapsToDeniedOrRestricted() {
        XCTAssertEqual(PermissionDisplayState.from(.denied), .deniedOrRestricted)
        XCTAssertEqual(PermissionDisplayState.from(.restricted), .deniedOrRestricted)
    }

    func testFrom_reducedAccuracy_mapsToReducedAccuracy() {
        XCTAssertEqual(PermissionDisplayState.from(.authorizedReducedAccuracy), .reducedAccuracy)
    }

    func testFrom_fullyAuthorizedOrNotDetermined_mapsToNone() {
        XCTAssertEqual(PermissionDisplayState.from(.notDetermined), .none)
        XCTAssertEqual(PermissionDisplayState.from(.authorizedWhenInUse), .none)
        XCTAssertEqual(PermissionDisplayState.from(.authorizedAlways), .none)
    }
}

final class ParticipantLocationDisplayStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFrom_neverReceivedLocation_isUnavailable() {
        let state = ParticipantLocationDisplayState.from(hasEverReceivedLocation: false, isStale: false, lastUpdated: nil)
        XCTAssertEqual(state, .unavailable)
    }

    func testFrom_receivedButStale_isStaleWithTimestamp() {
        let state = ParticipantLocationDisplayState.from(hasEverReceivedLocation: true, isStale: true, lastUpdated: now)
        XCTAssertEqual(state, .stale(lastUpdated: now))
    }

    func testFrom_receivedAndFresh_isNormal() {
        let state = ParticipantLocationDisplayState.from(hasEverReceivedLocation: true, isStale: false, lastUpdated: now)
        XCTAssertEqual(state, .normal)
    }
}

final class StaleDisplayDebouncerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testDisplay_firstCall_showsRawStateImmediately() {
        let debouncer = StaleDisplayDebouncer(minimumDwell: 5, now: { self.now })
        XCTAssertEqual(debouncer.display(for: .normal), .normal)
    }

    func testDisplay_flipWithinDwellWindow_holdsPreviousBucket() {
        var clock = now
        let debouncer = StaleDisplayDebouncer(minimumDwell: 5, now: { clock })

        XCTAssertEqual(debouncer.display(for: .normal), .normal)

        // Flickers to stale 1s later — inside the 5s dwell window.
        clock = now.addingTimeInterval(1)
        XCTAssertEqual(debouncer.display(for: .stale(lastUpdated: clock)), .normal, "Should hold .normal through a sub-dwell flicker")
    }

    func testDisplay_flipAfterDwellWindow_acceptsNewBucket() {
        var clock = now
        let debouncer = StaleDisplayDebouncer(minimumDwell: 5, now: { clock })

        XCTAssertEqual(debouncer.display(for: .normal), .normal)

        clock = now.addingTimeInterval(6)
        XCTAssertEqual(debouncer.display(for: .stale(lastUpdated: clock)), .stale(lastUpdated: clock))
    }

    func testDisplay_unavailableTransition_isNeverHeldBack() {
        var clock = now
        let debouncer = StaleDisplayDebouncer(minimumDwell: 5, now: { clock })

        XCTAssertEqual(debouncer.display(for: .normal), .normal)

        // Immediately loses all data — no dwell delay should apply.
        clock = now.addingTimeInterval(0.5)
        XCTAssertEqual(debouncer.display(for: .unavailable), .unavailable)

        // Recovering from unavailable is likewise immediate.
        clock = now.addingTimeInterval(1)
        XCTAssertEqual(debouncer.display(for: .normal), .normal)
    }

    func testDisplay_repeatedFlickeringNeverSettles_staysHeldUntilDwellFromLastFlipElapses() {
        var clock = now
        let debouncer = StaleDisplayDebouncer(minimumDwell: 5, now: { clock })

        XCTAssertEqual(debouncer.display(for: .normal), .normal)

        clock = now.addingTimeInterval(2)
        XCTAssertEqual(debouncer.display(for: .stale(lastUpdated: clock)), .normal)

        clock = now.addingTimeInterval(4)
        XCTAssertEqual(debouncer.display(for: .normal), .normal)

        clock = now.addingTimeInterval(6)
        XCTAssertEqual(debouncer.display(for: .stale(lastUpdated: clock)), .stale(lastUpdated: clock))
    }
}
