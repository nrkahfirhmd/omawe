# Omawe — Tech Report

## Team Introduction

Omawe is built by a small iOS team called Ex-Boyfriends: <br>
1. Kahfi, <br>
2. Gleen, <br>
3. Luat, <br>
4. Bintang, and <br>
5. Syed <br>
The team is developing Omawe as part of Challenge 4 at Apple Developer Academy @ BINUS, Bali.

## Starting Assumption

**What we assumed, before any real exploration:**

When we first came up with the idea for Omawe, we believed the technical implementation would be fairly straightforward. Since the app’s core purpose was simply to share trip progress among friends, we assumed we could build the entire experience using Apple’s native frameworks—ActivityKit for Live Activities, MapKit for maps and routing, Core Location for location tracking, and CloudKit for data synchronization. 

Because of that assumption, we expected most of our effort would go into refining the user experience and learning app-extension rather than solving complex technical problems. We planned to focus on making Live Activities feel truly useful and delightful by combining fluid animations, thoughtful haptic feedback, and interactive elements to create an experience that felt uniquely at home on iOS.

**Why We Believed That**

Our assumptions came from the belief that most of the technologies we needed were already provided by Apple’s ecosystem.

We expected Live Activities to be relatively straightforward to implement and integrate into the app, allowing us to quickly surface real-time trip information on the Lock Screen and Dynamic Island. Similarly, we assumed CloudKit would provide an easy-to-use backend for development and could be configured to support near real-time synchronization, with updates occurring instantly or at least every few seconds.

With those pieces seemingly in place, we believed the most challenging engineering problem would be optimizing location sharing. Our focus was on calculating each participant’s progress as efficiently as possible while minimizing battery consumption and maintaining a smooth, responsive user experience.

In short, we thought the challenge would be less about building the underlying infrastructure and more about refining the experience to feel seamless, efficient, and unmistakably native to iOS.

## The Revised Decision

**Final decision:**

- Location records are written to a **custom `CKRecordZone` per trip**, via a manual `CKRecord` save path (`LocationRecordMapper` + `CloudKitLocationSyncService`), not SwiftData's default zone. SwiftData is used for local app data; location sync is CloudKit-native and deliberately decoupled from it, with a **local offline queue** (`LocationUpdateQueueService`) as the documented mirroring strategy instead of trying to keep two persistence layers automatically consistent.
- **Every participant's device shares its own location**, not just the trip owner's. `ensureLocationSharing(for:)` is called on every status refresh so any device starts publishing as soon as it observes the trip is active.
- ETA/distance is computed via `MKDirections` with a **straight-line fallback** and a **200m movement threshold** before issuing a new request, to stay within Apple's MapKit rate limits
- The Live Activity's single `ContentState` **cannot represent every participant's status at once**, so an explicit selection policy was introduced: surface whoever is currently furthest from arrival, since that's the participant a viewer would most plausibly want to know about. This is flagged in code as an engineering default pending product sign-off, not a final UX decision.
- **Dark mode was dropped**, and the app is forced to light mode globally. **Localization was not implemented**

**What changed since Starting Assumption, and why:**

| Starting Assumption | What We Found | What We Did Instead |
|---|---|---|
| Apple's native frameworks would work together with minimal effort. | Integrating ActivityKit, CloudKit, Core Location, and MapKit required significantly more engineering than expected because each framework has different constraints and responsibilities. | Designed a dedicated architecture where each framework handles a specific responsibility instead of relying on automatic integration. |
| Live Activities would be straightforward to build and update. | ActivityKit manages update frequency and lifecycle, and implementing interactive actions is more limited than expected. | Redesigned the Live Activity experience around system constraints and focused on glanceable information rather than frequent interactions. |
| Button in Live Activities will be easy to implement. | There is 2 way to implement this, by using link or AppIntent . | We did it with link, but changes to AppIntent because link foreced us to open the lock screen in order for the action to happen. |
| CloudKit could provide near real-time synchronization. | CloudKit is designed for data synchronization, not low-latency real-time communication. | Tried to optimizing synchronization intervals and designed the app around eventual consistency while maintaining a responsive user experience. |
| CloudKit would be simple to set up during development. | Setting up containers, entitlements, sharing, and testing across multiple Apple IDs and devices proved considerably more complex. | Configured Apple Developer certificates, signing, and provisioning profiles to successfully build and test the app on physical iPhones. |
| Most development would focus on UI polish and user experience. | A significant amount of time was instead spent understanding framework limitations, synchronization behavior, permissions, and infrastructure. | Balanced engineering effort between solving technical challenges and refining the overall user experience. |
| Location sharing would be the primary technical challenge. | Efficient location sharing was important, but framework limitations and synchronization behavior became equally significant challenges. | Optimized location updates while redesigning the overall architecture to work within Apple's platform constraints. |

## App Track Addendum

### About the Frameworks

Omawe combines multiple Apple frameworks, each with a specific responsibility. ActivityKit is at the core of the experience, powering Live Activities and the Dynamic Island so users can track their group’s progress without repeatedly opening the app.

To keep Live Activities up to date, CloudKit synchronizes trip and location data between participants using per-trip record zones, CKShare invitations, and silent push notifications. Core Location captures foreground and background location updates, while MapKit provides routing and ETA calculations with a rate-limit-aware fallback. SwiftData stores local app data separately from CloudKit’s synchronization flow, Sign in with Apple handles authentication, and os.Logger is used for logging.

Our use case genuinely requires ActivityKit, AppIntent, and CloudKit. ActivityKit only presents information, AppIntent for action in live activities, while CloudKit synchronizes the real-time data behind it. Together, they enable the lock-screen-first experience that defines Omawe.

### About Accessibility and Localization

Accessibility has been considered from the beginning of Omawe’s design. The current implementation supports Larger Text, Haptic Feedback, and Differentiate Without Color, ensuring that key interactions remain accessible to a wider range of users and are not solely dependent on visual cues.

Localization has not yet been implemented, and the app is currently available only in English. As the product evolves, we plan to add support for multiple languages, starting with Bahasa Indonesia, Vietnamese, and other languages to better serve a broader audience.

### About Privacy

Location privacy has been a key consideration throughout Omawe’s development rather than an afterthought. We designed the permission flow to be transparent and respectful of users’ privacy by clearly explaining why location access is needed and only requesting additional permissions when they become necessary. Users first grant location access while using the app, and background location is requested only when they intentionally start a trip—not during the initial onboarding experience.

Location sharing is also temporary and tied to an active trip. Once a trip ends or a participant leaves, their location is no longer shared, reinforcing the idea that Omawe only tracks users when it provides value. We are also mindful of Apple’s stricter review process for apps that use background location and continue to evaluate how features such as approximate location should fit into the overall product experience while maintaining user trust and privacy.
