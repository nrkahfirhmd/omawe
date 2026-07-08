//
//  WidgetContentStateAggregatorTests.swift
//  OmaweTests
//

import XCTest
import CloudKit
@testable import Omawe

final class WidgetContentStateAggregatorTests: XCTestCase {

    private func state(
        user: String,
        etaMinutes: Int?,
        distanceKm: Double,
        status: ParticipantTripStatus
    ) -> ParticipantTripState {
        ParticipantTripState(
            userID: CKRecord.ID(recordName: user),
            etaMinutes: etaMinutes,
            distanceKm: distanceKm,
            status: status,
            isStale: status == .offline,
            usedFallback: false
        )
    }

    func testAggregate_emptyParticipants_returnsDefinedDefaultNotCrash() {
        let content = WidgetContentStateAggregator.aggregate(participantStates: [], displayNames: [:])

        XCTAssertEqual(content.arrivedCount, 0)
        XCTAssertEqual(content.etaMinutes, 0)
        XCTAssertEqual(content.distanceKm, 0)
        XCTAssertFalse(content.statusMessage.isEmpty)
    }

    func testAggregate_allArrived_reportsArrivedCountAndNoSelection() {
        let states = [
            state(user: "a", etaMinutes: 0, distanceKm: 0.05, status: .arrived),
            state(user: "b", etaMinutes: 0, distanceKm: 0.02, status: .arrived)
        ]

        let content = WidgetContentStateAggregator.aggregate(participantStates: states, displayNames: [:])

        XCTAssertEqual(content.arrivedCount, 2)
        XCTAssertEqual(content.statusMessage, "Everyone has arrived")
    }

    func testAggregate_selectsFurthestFromArrivalAmongNonArrived() {
        let near = state(user: "near", etaMinutes: 2, distanceKm: 0.8, status: .nearDestination)
        let far = state(user: "far", etaMinutes: 30, distanceKm: 20, status: .onTheWay)
        let arrived = state(user: "arrived", etaMinutes: 0, distanceKm: 0.01, status: .arrived)

        let content = WidgetContentStateAggregator.aggregate(
            participantStates: [near, far, arrived],
            displayNames: ["far".ckRecordID: "Bintang"]
        )

        XCTAssertEqual(content.arrivedCount, 1)
        XCTAssertEqual(content.etaMinutes, 30)
        XCTAssertEqual(content.distanceKm, 20)
        XCTAssertTrue(content.statusMessage.contains("Bintang"))
    }

    func testAggregate_missingDisplayName_fallsBackToGenericName() {
        let states = [state(user: "unknown", etaMinutes: 5, distanceKm: 1, status: .onTheWay)]

        let content = WidgetContentStateAggregator.aggregate(participantStates: states, displayNames: [:])

        XCTAssertTrue(content.statusMessage.contains("Someone"))
    }

    func testAggregate_offlineParticipant_reportsUnavailableMessage() {
        let states = [state(user: "offline-user", etaMinutes: nil, distanceKm: 3, status: .offline)]

        let content = WidgetContentStateAggregator.aggregate(
            participantStates: states,
            displayNames: ["offline-user".ckRecordID: "Kahfi"]
        )

        XCTAssertTrue(content.statusMessage.contains("unavailable"))
        XCTAssertEqual(content.etaMinutes, 0)
    }
}

private extension String {
    var ckRecordID: CKRecord.ID { CKRecord.ID(recordName: self) }
}
