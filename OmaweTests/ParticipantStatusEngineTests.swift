import XCTest
@testable import Omawe

final class ParticipantStatusEngineTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func input(
        distanceMeters: Double,
        etaMinutes: Int?,
        secondsSinceUpdate: TimeInterval = 0,
        isBackgrounded: Bool = false,
        etaAtLastOnTheWay: TimeInterval? = nil
    ) -> ParticipantStatusInput {
        ParticipantStatusInput(
            distanceMeters: distanceMeters,
            etaMinutes: etaMinutes,
            lastUpdate: now.addingTimeInterval(-secondsSinceUpdate),
            isBackgrounded: isBackgrounded,
            etaAtLastOnTheWay: etaAtLastOnTheWay,
            now: now
        )
    }

    // MARK: - Individual transitions

    func testStatus_farAwayFreshData_isOnTheWay() {
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 5_000, etaMinutes: 20, etaAtLastOnTheWay: 20 * 60))
        XCTAssertEqual(status, .onTheWay)
    }

    func testStatus_withinNearDestinationDistance_isNearDestination() {
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 500, etaMinutes: 10, etaAtLastOnTheWay: 10 * 60))
        XCTAssertEqual(status, .nearDestination)
    }

    func testStatus_withinArrivedDistance_isArrived() {
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 50, etaMinutes: 1, etaAtLastOnTheWay: 60))
        XCTAssertEqual(status, .arrived)
    }

    func testStatus_etaRegressedPastThreshold_isDelayed() {
        // Baseline ETA was 100s; current ETA is 800s — 700s regression hits
        // LocationCore's delayedETAThresholdSeconds (600s) exactly.
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 5_000, etaMinutes: Int(800 / 60), etaAtLastOnTheWay: 100))
        XCTAssertEqual(status, .delayed)
    }

    func testStatus_staleData_isOffline() {
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 5_000, etaMinutes: 10, secondsSinceUpdate: 40, isBackgrounded: false, etaAtLastOnTheWay: 10 * 60))
        XCTAssertEqual(status, .offline)
    }

    // MARK: - Precedence at overlapping boundaries

    func testStatus_offlineAndArrived_offlineWins() {
        // Both offline (stale, foregrounded) and within arrived distance —
        // offline must take priority per ETA-2's precedence recommendation.
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 10, etaMinutes: 0, secondsSinceUpdate: 40, isBackgrounded: false))
        XCTAssertEqual(status, .offline)
    }

    func testStatus_arrivedAndDelayed_arrivedWins() {
        // Within arrived distance but ETA also regressed past the delayed
        // threshold — arrived should win since the participant is physically there.
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 50, etaMinutes: Int(800 / 60), etaAtLastOnTheWay: 100))
        XCTAssertEqual(status, .arrived)
    }

    func testStatus_delayedAndNearDestination_delayedWins() {
        let status = ParticipantStatusEngine.status(for: input(distanceMeters: 500, etaMinutes: Int(800 / 60), etaAtLastOnTheWay: 100))
        XCTAssertEqual(status, .delayed)
    }

    // MARK: - ParticipantStatusTracker: first-update baseline + rolling updates

    func testTracker_firstUpdate_defaultsToOnTheWayRegardlessOfDistance() {
        let tracker = ParticipantStatusTracker()
        // Even a far-but-plausible reading on the very first sample must not
        // be reported as delayed — there's no baseline to compare against yet.
        let status = tracker.update(distanceMeters: 5_000, etaMinutes: 30, lastUpdate: now, isBackgrounded: false, now: now)
        XCTAssertEqual(status, .onTheWay)
    }

    func testTracker_etaRegressesAcrossUpdates_becomesDelayed() {
        let tracker = ParticipantStatusTracker()
        _ = tracker.update(distanceMeters: 5_000, etaMinutes: 10, lastUpdate: now, isBackgrounded: false, now: now)

        // ETA balloons from 10 min baseline to 25 min (900s regression > 600s threshold).
        let later = now.addingTimeInterval(120)
        let status = tracker.update(distanceMeters: 5_000, etaMinutes: 25, lastUpdate: later, isBackgrounded: false, now: later)

        XCTAssertEqual(status, .delayed)
    }

    func testTracker_baselineOnlyAdvancesWhileOnTheWay() {
        let tracker = ParticipantStatusTracker()
        _ = tracker.update(distanceMeters: 5_000, etaMinutes: 10, lastUpdate: now, isBackgrounded: false, now: now)

        // Regress into delayed — baseline should NOT reset to this new ETA.
        let t1 = now.addingTimeInterval(60)
        XCTAssertEqual(
            tracker.update(distanceMeters: 5_000, etaMinutes: 25, lastUpdate: t1, isBackgrounded: false, now: t1),
            .delayed
        )

        // A further, smaller ETA bump from the *original* baseline (10 min)
        // should still read as delayed, proving the baseline didn't silently
        // reset to 25 while status was .delayed.
        let t2 = now.addingTimeInterval(120)
        XCTAssertEqual(
            tracker.update(distanceMeters: 5_000, etaMinutes: 22, lastUpdate: t2, isBackgrounded: false, now: t2),
            .delayed
        )
    }
}
