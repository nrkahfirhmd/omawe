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
    ///
    /// `prefetchedLocations` lets a caller that already fetched this tick's
    /// locations for its own purposes (e.g. `LocationView` populating map
    /// pins) hand them over instead of this method issuing its own second,
    /// redundant `fetchLatestLocations` round trip for the same data.
    func refresh(
        tripID: CKRecord.ID,
        destination: CLLocationCoordinate2D,
        isBackgrounded: Bool = false,
        prefetchedLocations: [CKRecord.ID: LocationSample]? = nil
    ) async {
        do {
            let locations: [CKRecord.ID: LocationSample]
            if let prefetchedLocations {
                locations = prefetchedLocations
            } else {
                locations = try await locationSyncService.fetchLatestLocations(for: tripID)
            }
            errorMessage = nil

            // Route resolution is the expensive, network-bound step
            // (`MKDirections` per participant) — fan it out concurrently
            // instead of awaiting one participant at a time, which used to
            // multiply this tick's latency by participant count. Only the
            // pure network call runs inside the task group; `routeCache` and
            // `statusTrackers` are read/written back on this single task
            // afterward so no shared mutable state is touched concurrently.
            let localRouteCache = routeCache
            let resolved: [(userID: CKRecord.ID, sample: LocationSample, result: RouteResult?, usedFallback: Bool, newCacheEntry: (CLLocationCoordinate2D, RouteResult)?)] = await withTaskGroup(of: (CKRecord.ID, LocationSample, RouteResult?, Bool, (CLLocationCoordinate2D, RouteResult)?).self) { group in
                for (userID, sample) in locations {
                    group.addTask { [routeProvider, movementThresholdMeters] in
                        let origin = CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude)
                        let (result, usedFallback, newEntry) = await Self.resolveRoute(
                            origin: origin,
                            destination: destination,
                            cached: localRouteCache[userID],
                            movementThresholdMeters: movementThresholdMeters,
                            routeProvider: routeProvider
                        )
                        return (userID, sample, result, usedFallback, newEntry)
                    }
                }

                var collected: [(CKRecord.ID, LocationSample, RouteResult?, Bool, (CLLocationCoordinate2D, RouteResult)?)] = []
                for await item in group {
                    collected.append(item)
                }
                return collected
            }

            var updated: [CKRecord.ID: ParticipantTripState] = [:]
            for (userID, sample, result, usedFallback, newCacheEntry) in resolved {
                if let newCacheEntry {
                    routeCache[userID] = newCacheEntry
                }
                updated[userID] = finalizeState(
                    userID: userID,
                    sample: sample,
                    destination: destination,
                    result: result,
                    usedFallback: usedFallback,
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

    /// Turns an already-resolved route (or fallback) into the participant's
    /// discrete status/ETA/distance. Reads/writes `statusTrackers` — only
    /// ever called serially from `refresh`, after the concurrent route
    /// fan-out has completed, so this dictionary is never touched from more
    /// than one task at a time.
    private func finalizeState(
        userID: CKRecord.ID,
        sample: LocationSample,
        destination: CLLocationCoordinate2D,
        result: RouteResult?,
        usedFallback: Bool,
        isBackgrounded: Bool
    ) -> ParticipantTripState {
        let origin = CLLocationCoordinate2D(latitude: sample.latitude, longitude: sample.longitude)

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
    /// `MKDirections` was skipped or failed for this tick. `static` and
    /// parameterized (no `self` access) so it's safe to call concurrently
    /// from multiple tasks in `refresh`'s route fan-out — it touches no
    /// shared mutable state; the caller merges `newCacheEntry` back into
    /// `routeCache` serially afterward.
    private static func resolveRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        cached: (coordinate: CLLocationCoordinate2D, result: RouteResult)?,
        movementThresholdMeters: CLLocationDistance,
        routeProvider: RouteProviding
    ) async -> (result: RouteResult?, usedFallback: Bool, newCacheEntry: (CLLocationCoordinate2D, RouteResult)?) {
        if let cached {
            let moved = LocationCore.straightLineDistance(
                from: Location(coordinate: cached.coordinate),
                to: Location(coordinate: origin)
            )
            if moved < movementThresholdMeters {
                return (cached.result, false, nil)
            }
        }

        do {
            let result = try await routeProvider.route(from: origin, to: destination)
            return (result, false, (origin, result))
        } catch {
            return (nil, true, nil)
        }
    }
}
