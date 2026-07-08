//
//  ETAAccuracySamplerTests.swift
//  OmaweTests
//

import XCTest
import CloudKit
@testable import Omawe

private final class FakeAnalyticsLogging: AnalyticsLogging {
    private(set) var events: [AnalyticsEvent] = []

    func log(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

final class ETAAccuracySamplerTests: XCTestCase {

    private let userID = CKRecord.ID(recordName: "user-1")
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func state(status: ParticipantTripStatus, etaMinutes: Int?, isStale: Bool = false) -> ParticipantTripState {
        ParticipantTripState(
            userID: userID,
            etaMinutes: etaMinutes,
            distanceKm: 1,
            status: status,
            isStale: isStale,
            usedFallback: false
        )
    }

    func testRecordTransitions_arrivalAfterOnTheWayBaseline_logsPredictedVsActual() {
        var clock = now
        let analytics = FakeAnalyticsLogging()
        let sampler = ETAAccuracySampler(analytics: analytics, now: { clock })

        // Baseline: predicted 10 minutes (600s) while en route.
        sampler.recordTransitions(
            previous: [:],
            updated: [userID: state(status: .onTheWay, etaMinutes: 10)]
        )
        XCTAssertTrue(analytics.events.isEmpty)

        // 500 real seconds later, participant arrives.
        clock = now.addingTimeInterval(500)
        sampler.recordTransitions(
            previous: [userID: state(status: .onTheWay, etaMinutes: 10)],
            updated: [userID: state(status: .arrived, etaMinutes: 0)]
        )

        XCTAssertEqual(analytics.events, [.etaAccuracySample(predictedSeconds: 600, actualSeconds: 500)])
    }

    func testRecordTransitions_noBaselineBeforeArrival_logsNothing() {
        let analytics = FakeAnalyticsLogging()
        let sampler = ETAAccuracySampler(analytics: analytics, now: { self.now })

        // Arrives on the very first tick this participant is ever seen —
        // no prior "en route" baseline was ever captured.
        sampler.recordTransitions(
            previous: [:],
            updated: [userID: state(status: .arrived, etaMinutes: 0)]
        )

        XCTAssertTrue(analytics.events.isEmpty)
    }

    func testRecordTransitions_remainingArrivedAcrossTicks_logsOnlyOnce() {
        var clock = now
        let analytics = FakeAnalyticsLogging()
        let sampler = ETAAccuracySampler(analytics: analytics, now: { clock })

        sampler.recordTransitions(previous: [:], updated: [userID: state(status: .onTheWay, etaMinutes: 5)])

        clock = now.addingTimeInterval(200)
        sampler.recordTransitions(
            previous: [userID: state(status: .onTheWay, etaMinutes: 5)],
            updated: [userID: state(status: .arrived, etaMinutes: 0)]
        )
        XCTAssertEqual(analytics.events.count, 1)

        // Still arrived on the next tick — not a new transition, must not
        // fire a second sample for the same arrival.
        clock = now.addingTimeInterval(220)
        sampler.recordTransitions(
            previous: [userID: state(status: .arrived, etaMinutes: 0)],
            updated: [userID: state(status: .arrived, etaMinutes: 0)]
        )

        XCTAssertEqual(analytics.events.count, 1)
    }

    func testRecordTransitions_staleReadingNeverBecomesBaseline() {
        var clock = now
        let analytics = FakeAnalyticsLogging()
        let sampler = ETAAccuracySampler(analytics: analytics, now: { clock })

        // A stale reading shouldn't seed a baseline — it's not a trustworthy
        // "prediction," it's a stale leftover.
        sampler.recordTransitions(previous: [:], updated: [userID: state(status: .offline, etaMinutes: 10, isStale: true)])

        clock = now.addingTimeInterval(50)
        sampler.recordTransitions(
            previous: [userID: state(status: .offline, etaMinutes: 10, isStale: true)],
            updated: [userID: state(status: .arrived, etaMinutes: 0)]
        )

        XCTAssertTrue(analytics.events.isEmpty)
    }
}
