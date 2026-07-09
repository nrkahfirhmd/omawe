//
//  TripStatusViewModel.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import CoreLocation
import CloudKit
import MapKit

/// Per-participant computed trip status: ETA-1's raw ETA/distance plus
/// ETA-2's derived state machine. One value per participant currently
/// reporting a location for the trip.
struct ParticipantTripState: Equatable {
    let userID: CKRecord.ID
    var etaMinutes: Int?
    var distanceKm: Double
    var status: ParticipantTripStatus
    var isStale: Bool
    /// True when this reading came from the straight-line fallback because
    /// `MKDirections` failed (offline, no route found, rate-limited) rather
    /// than an actual route.
    var usedFallback: Bool
}

/// Owns real ETA/distance per participant (ETA-1), using `MKDirections` for
/// a route-based estimate with a straight-line fallback for offline/degraded
/// cases, and derives each participant's discrete status (ETA-2) on top.
@Observable
final class TripStatusViewModel {
    private let locationSyncService: LocationSyncServiceProtocol
    private let routeProvider: RouteProviding
    private let movementThresholdMeters: CLLocationDistance
    private let now: () -> Date

    private(set) var participantStates: [CKRecord.ID: ParticipantTripState] = [:]
    var errorMessage: String?
    
    /// Tracks the absolute maximum distance ever reported by any participant in this trip.
    /// This provides a fixed visual scale for progress bars so they don't dynamically shrink.
    private(set) var maxDistanceEverSeen: Double = 0.0

    /// Last coordinate an `MKDirections` request was actually made for, plus
    /// its result — Apple rate-limits this API, so a sub-threshold move
    /// reuses the cached route instead of re-requesting one every tick.
    private var routeCache: [CKRecord.ID: (coordinate: CLLocationCoordinate2D, result: RouteResult)] = [:]
    private var statusTrackers: [CKRecord.ID: ParticipantStatusTracker] = [:]

    init(
        locationSyncService: LocationSyncServiceProtocol,
        routeProvider: RouteProviding = MKDirectionsRouteProvider(),
        movementThresholdMeters: CLLocationDistance = 200,
        now: @escaping () -> Date = { Date() }
    ) {
        self.locationSyncService = locationSyncService
        self.routeProvider = routeProvider
        self.movementThresholdMeters = movementThresholdMeters
        self.now = now
    }

    /// Fetches latest per-participant locations for `tripID` and recomputes
    /// ETA/distance/status against `destination`. Call this whenever new
    /// location data is expected (LOC-1 sync tick/subscription fire) — not
    /// from an independent fixed timer.
    func refresh(tripID: CKRecord.ID, destination: CLLocationCoordinate2D, isBackgrounded: Bool = false) async {
        do {
            let locations = try await locationSyncService.fetchLatestLocations(for: tripID)
            errorMessage = nil

            var updated: [CKRecord.ID: ParticipantTripState] = [:]
            for (userID, sample) in locations {
                updated[userID] = await computeState(
                    userID: userID,
                    sample: sample,
                    destination: destination,
                    isBackgrounded: isBackgrounded
                )
            }
            participantStates = updated
            
            let currentMax = updated.values.map { $0.distanceKm }.max() ?? 0.0
            if currentMax > maxDistanceEverSeen {
                maxDistanceEverSeen = currentMax
            }
        } catch {
            errorMessage = ErrorHelper.simplify(error)
        }
    }

    /// NFR-4: exposes the already-computed route for `userID` so a map view
    /// can draw it directly, instead of issuing its own separate
    /// `MKDirections` request for the same origin/destination this view
    /// model already resolved during `refresh`.
    func route(for userID: CKRecord.ID) -> MKRoute? {
        routeCache[userID]?.result.route
    }

    private func computeState(
        userID: CKRecord.ID,
        sample: LocationSample,
        destination: CLLocationCoordinate2D,
        isBackgrounded: Bool
    ) async -> ParticipantTripState {
        let origin = CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude)
        let (result, usedFallback) = await resolveRoute(userID: userID, origin: origin, destination: destination)

        let tracker = statusTrackers[userID] ?? {
            let tracker = ParticipantStatusTracker()
            statusTrackers[userID] = tracker
            return tracker
        }()

        let etaMinutes = result.map { Int(($0.etaSeconds / 60).rounded()) }
        let distanceMeters = result?.distanceMeters ?? LocationCore.straightLineDistance(
            from: Location(coordinate: origin),
            to: Location(coordinate: destination)
        )

        let status = tracker.update(
            distanceMeters: distanceMeters,
            etaMinutes: etaMinutes,
            lastUpdate: sample.recordedAt,
            isBackgrounded: isBackgrounded,
            now: now()
        )

        let isStale = LocationCore.isOffline(
            lastUpdate: sample.recordedAt,
            isBackgrounded: isBackgrounded,
            now: now()
        )

        return ParticipantTripState(
            userID: userID,
            etaMinutes: etaMinutes,
            distanceKm: distanceMeters / 1000,
            status: status,
            isStale: isStale,
            usedFallback: usedFallback
        )
    }

    /// Route-succeeds-use-it / route-fails-use-straight-line, throttled by
    /// `movementThresholdMeters`. Returns `usedFallback: true` whenever
    /// `MKDirections` was skipped or failed for this tick.
    private func resolveRoute(
        userID: CKRecord.ID,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async -> (RouteResult?, usedFallback: Bool) {
        if let cached = routeCache[userID] {
            let moved = LocationCore.straightLineDistance(
                from: Location(coordinate: cached.coordinate),
                to: Location(coordinate: origin)
            )
            if moved < movementThresholdMeters {
                return (cached.result, false)
            }
        }

        do {
            let result = try await routeProvider.route(from: origin, to: destination)
            routeCache[userID] = (origin, result)
            return (result, false)
        } catch {
            return (nil, true)
        }
    }
}
