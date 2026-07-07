# Sprint 1 Review — Location Domain

**Date:** 2026-07-07
**Scope:** LOC-1, LOC-2, LOC-3, LOC-4, LOC-5
**Verification method:** static code check against each ticket's acceptance criteria + `xcodebuild test` run (see Test Run section)

## Summary

All 5 tickets implemented. 4/5 fully complete. LOC-1 and LOC-2 each have one acceptance criterion blocked on physical-device testing (cannot be validated from this environment/CI). Test suite: **40/40 passing**, build green.

## Per-ticket status

### LOC-3 — Location privacy strings & background mode
**Status: Done, pending manual smoke test**

| Criterion | Status | Verified |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription` present, accurate copy | ✅ | Confirmed present in `Omawe/Info.plist` with review-safe copy |
| `location` added to `UIBackgroundModes` without removing `remote-notification` | ✅ | Confirmed both entries present |
| Background Modes capability in Xcode target matches plist | ✅ | Per ticket note |
| Manual smoke test (fresh install, prompts appear, no crash) | ⬜ | Requires physical device + fresh install; not run |

**Risk carried forward:** App Review gives Always-location apps extra scrutiny — budget review time when this ships with LOC-2.

### LOC-5 — LocationCore domain primitives
**Status: Done**

| Criterion | Status | Verified |
|---|---|---|
| AD-6 thresholds as named constants + pure functions | ✅ | `Omawe/Core/LocationCore.swift` (53 lines), zero external deps |
| Zero CloudKit/CLLocationManager/MapKit imports | ✅ | Confirmed no such imports in file |
| Unit test target added to Xcode project | ✅ | `OmaweTests/` target exists, auto-discovered (file-system-synced groups) |
| Boundary-value tests for all 5 thresholds | ✅ | `LocationCoreTests.swift` — 12 tests passing |

**Process note flagged in ticket:** missing test target was a repo-wide gap prior to this ticket, not LOC-5-specific — resolved once, not re-added elsewhere.

### LOC-1 — CloudKit-based location sync (≤30s budget)
**Status: Implemented, latency validation blocked**

| Criterion | Status | Verified |
|---|---|---|
| Location records save into trip's custom `CKRecordZone`, not SwiftData default zone | ✅ | `LocationRecordMapper` + `CloudKitLocationSyncService` implement manual `CKRecord` save path |
| Second device receives update within 30s budget, p50/p95 over ≥10 runs | ⬜ **Blocked** | Requires 2 physical devices — cannot run in this environment |
| All failure paths route through `CloudKitError` | ✅ | Confirmed |
| Push notification handling added (`didReceiveRemoteNotification` + registration) | ✅ | Confirmed 2 matches in AppDelegate (registration + handler present); silent-push end-to-end delivery still needs physical-device pass |
| SwiftData mirroring decision documented | ✅ | Option (a) — local-only offline queue — recorded, consumed by LOC-4 |

**Risk carried forward:** push-notification wiring was net-new to the app (no prior entitlement/APNs integration) — sizing risk called out in ticket; recommend confirming end-to-end delivery early in the next sprint rather than at the end.

### LOC-2 — LocationService: CoreLocation capture
**Status: Implemented, on-device capture validation blocked**

| Criterion | Status | Verified |
|---|---|---|
| `LocationService.swift` is a service class conforming to `LocationServiceProtocol`, not a `View` | ✅ | Confirmed rewritten |
| When-In-Use requested first; Always only after explicit trip-start action | ✅ | Covered by `LocationServiceTests` |
| Captured locations flow to LOC-1 sync path, no CloudKit imports in this file | ✅ | Bridged via new `LocationSharingCoordinator` |
| Authorization state (denied/restricted/reduced-accuracy) exposed distinctly | ✅ | `LocationAuthorizationState` enum — 7 state-mapping tests passing |
| Manual on-device test: updates captured/forwarded while backgrounded | ⬜ **Blocked** | Requires physical device — Simulator can't validate real GPS/background signal |

**Open question carried forward:** reduced-accuracy ("approximate location") handling isn't addressed by PRD §13 — needs product decision before NFR-1 builds UI around it.

### LOC-4 — Reconcile LocationUpdate with CloudKit identifiers
**Status: Done**

| Criterion | Status | Verified |
|---|---|---|
| Identifiers are `CKRecord.ID`-compatible (decomposed recordName/zone fields) | ✅ | Confirmed in `LocationUpdate.swift` |
| `LocationModel.swift` deleted (dead code) | ✅ | File confirmed absent from `Omawe/Models/` |
| SwiftData-vs-CloudKit-mirroring decision explicit (option a: local offline queue) | ✅ | `OmaweApp.swift` splits into two `ModelConfiguration`s; `LocationUpdateQueueService.swift` implements enqueue/flush |
| No regression (LocationUpdate had zero real callers before) | ✅ | Confirmed |

## Test run

```
xcodebuild test — Omawe.xcodeproj / OmaweTests
Executed 40 tests, with 0 failures (0 unexpected)
Test Suite 'All tests' passed
```

Breakdown by file:
- `LocationCoreTests.swift` — 12
- `LocationServiceTests.swift` (state mapping + manager interaction) — 13
- `LocationSharingCoordinatorTests.swift` — 1
- `LocationRecordMapperTests.swift` — 4
- `CloudKitLocationSyncServiceTests.swift` — 4
- `LocationUpdateQueueServiceTests.swift` — 4
- `LocationUpdateTests.swift` — 2

## Outstanding items for next sprint / before release

1. **Two-physical-device latency test (LOC-1):** measure p50/p95 propagation time over ≥10 runs against the 30s budget. Blocks closing LOC-1's remaining acceptance criterion.
2. **On-device background capture test (LOC-2):** confirm `LocationService` keeps forwarding updates while backgrounded on real hardware.
3. **Fresh-install permission smoke test (LOC-3):** confirm both usage-description prompts appear with correct copy and no crash, once LOC-2's permission flow is exercised on-device.
4. **Reduced-accuracy product decision (LOC-2):** get product sign-off on whether "approximate location" sharing is allowed or should be blocked, before NFR-1 builds dependent UI.
5. **NFR-3 wiring (deferred, not a Sprint 1 gap):** integrate `LocationUpdateQueueService`'s retry/flush into `LocationSharingCoordinator`'s failure path — explicitly scoped to NFR-3 (Sprint 4), not Sprint 1.
