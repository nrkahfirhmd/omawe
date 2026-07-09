# Omawe — Exploration Log

## The Exploration Log

### What we browsed, and what surprised us

The first major challenge was CloudKit. We initially expected it to provide near real-time synchronization, but we discovered that CloudKit is designed for data synchronization rather than low-latency, real-time communication. This meant we had to rethink how location updates and trip progress should be delivered while still providing a responsive experience. Even setting up CloudKit during development proved to be more complicated than expected, requiring additional configuration, entitlements, containers, sharing, and testing across multiple Apple IDs and devices.

We also learned that ActivityKit is far more opinionated than we had anticipated. While Live Activities provide an excellent glanceable experience, update frequency and lifecycle are managed by the system rather than the app itself. Features that initially seemed straightforward—such as adding interactive action buttons or frequently updating trip progress—required much more exploration and experimentation to implement correctly within Apple’s constraints.

Finally, we discovered that combining these frameworks was not simply a matter of connecting APIs. Building a reliable, battery-efficient, privacy-conscious, and responsive trip tracking experience required carefully balancing the capabilities and limitations of ActivityKit, CloudKit, Core Location, and MapKit. Instead of focusing solely on polishing the user experience as we originally expected, a significant portion of our effort shifted toward understanding the frameworks themselves and designing around their constraints.

### What we actually built or tested in code (not just read about)

* Implemented all-participants routing to calculate each participant’s progress and ETA toward a shared destination.
* Built and tested low-latency CloudKit synchronization, currently updating and fetching trip data approximately every 5 seconds.
* Implemented ownership transfer, allowing another participant to become the trip owner if the original creator leaves.
* Developed offline handling to improve the app’s behavior during temporary network interruptions.
* Integrated Sign in with Apple using iCloud for secure user authentication.
* Configured Apple Developer certificates and provisioning to successfully build and deploy the app on physical iPhones.
* Wrote Swift tests to validate key components and improve code reliability.
* Implemented trip sharing through share links, allowing other users to join a trip easily.

### What we discovered that we didn't expect

* CloudKit is not designed for real-time communication. We initially assumed CloudKit could support near real-time location synchronization, but we learned that it is optimized for data synchronization rather than low-latency updates. This required us to redesign how frequently location data should be synchronized while keeping the experience responsive.
* CloudKit development setup is more complicated than expected. Configuring CloudKit containers, entitlements, sharing, and testing across multiple Apple IDs and physical devices introduced significantly more complexity than we had anticipated.
* Implementing interactive Live Activities is not straightforward. Although Live Activities appear simple from the user’s perspective, adding action buttons and designing around ActivityKit’s lifecycle and system-managed behavior required much more exploration than expected.
* Share links are less useful during development than we expected. While CloudKit sharing works technically, the experience is intended for apps distributed through the App Store. During development, testing shared trips requires additional setup with development builds and Apple IDs, making the feature much less seamless than it will be after the app is publicly released.

## What We Tried and Dropped

**We considered:** letting SwiftData's default CloudKit sync handle location records like the rest of the app's data.<br>
**We dropped it because:** trip-scoped sharing and cleanup (per-trip zones, revocable invitations, deleting a trip's data when it ends) don't map cleanly onto SwiftData's single default zone. We kept SwiftData for local app data and built a separate, manual CloudKit path for location sync. 

**We considered:** computing ETA/distance with a fresh `MKDirections` call on every location update, for the freshest possible number.<br>
**We dropped it because:** that frequency risks Apple's MapKit rate limits under real multi-participant, multi-update load. We added a 200m movement threshold before issuing a new request and a straight-line-distance fallback for when a fresh route call isn't warranted or fails.

**We considered:** computing a route polyline per participant, so the map could show everyone's path.<br>
**We dropped it because:** of the same `MKDirections` rate-limit tradeoff — we render a route for the current user only, with every participant's last-known point still shown as a map annotation.

**We considered:** keeping `Trip.ownerID` as the source of truth for "who's the owner" alongside `Participant.role`.<br>
**We dropped it because:** the two could disagree after an ownership transfer (the immutable `Trip.ownerID` wouldn't reflect a reassignment). We consolidated every owner-gated check onto `Participant.role` only.

**We considered:** dark mode support and localization as standard v1 scope.<br>
**We dropped it because:** they weren't essential to proving out the core trip-tracking/Live Activity experience, and building both properly (a second color scheme, a strings catalog and translation pass) would have taken time away from the sync/status/Live-Activity work that the concept actually depends on. The app is forced to light mode globally; all copy is hardcoded English.

## Real Limitations Hit

### What broke, what didn't behave the way the documentation said it would

- **Live Activity `ContentState` update frequency is system-managed, not on-demand.** We built a Live Activity UI before confirming what update cadence ActivityKit would actually allow, and had to revisit both the design and the update-throttling logic once we understood the real constraint 
- **A single `ContentState` can't represent an arbitrary number of participants.** The widget has exactly one `statusMessage`/`etaMinutes`/`distanceKm` slot for a trip that can have many people in it — there was no framework-level answer for "whose status wins," so we had to invent a selection policy (furthest-from-arrival) ourselves and flag it explicitly as provisional pending product input.
- **CloudKit's `CKShare` access model doesn't revoke on `leaveTrip`.** Removing a `Participant` record doesn't remove the underlying share access, which is why departed members stayed stuck seeing an "ended" trip that hadn't actually been cleaned up for them yet.
- **Trip.ownerID and Participant.role could silently disagree** after a concurrent ownership transfer, since one is immutable on the `Trip` record and the other is mutable per-participant — a race we had to guard against explicitly (earliest-joined participant promoted, guarded against concurrent-leave races) rather than something CloudKit's conflict resolution handled for us.

### How we worked around it

- Throttled Live Activity updates to meaningful content changes only, and treated `Activity.request` failures as soft (non-fatal) failures rather than something the rest of the app needs to react to.
- Changed `activeTrip` resolution in `HomeView`/`TripsListView` to require the current user still be a listed participant of the trip, closing the "stuck after leaving" gap without needing to solve `CKShare` revocation itself.
- Dropped the disagreeing `Trip.ownerID` signal entirely in favor of a single source of truth (`Participant.role`), and added a deterministic, documented tie-break (earliest `joinedAt`) for ownership transfer instead of leaving it ambiguous.
- Added a jittered exponential backoff (`RetryExecutor`/`RetryBackoff`) capped well inside the 30-second sync budget for retryable `CKError`s, and routed exhausted retries into the offline queue instead of silently dropping them — so transient CloudKit failures degrade gracefully instead of just failing once and giving up.