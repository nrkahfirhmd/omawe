# Omawe

Group trips, without the "where are you?" texts.

Omawe turns passive location sharing into active trip awareness. Instead of everyone opening Maps, refreshing locations, and texting "where are you now?", Omawe automatically shows who's on the way, who's stuck in traffic, and who's running late — right on the Lock Screen — so the group knows exactly when to leave without sending a single message.

## Why

Coordinating a group ride today is manual and repetitive: check Maps, text someone, guess their ETA, repeat. The friction gets worse as the group grows, and self-reported ETAs are rarely accurate (the "I'm 5 minutes away" lie). Omawe replaces that loop with a shared, glanceable view of everyone's progress toward one destination.

## How it works

- **Create or join a trip** around a single shared destination.
- **Live Activities** on the Lock Screen and Dynamic Island show each participant's status (en route, delayed, arrived) and ETA in real time, so trip status is understandable in a glance — no need to unlock the phone.
- **Time-boxed, explicit location sharing** — sharing is opt-in per trip, clearly scoped, and ends automatically when the trip is over.
- **Graceful under bad signal** — when GPS or network drops, Omawe shows an honest "last seen X ago" instead of a misleading live status.
- **Built to be battery-conscious** — background location and Live Activity updates are tuned to avoid draining the battery over a full trip.

## Project structure

```
Omawe/               Main app target (SwiftUI)
  Core/              Location handling, participant status engine, map region fitting
  Models/             Trip, Participant, Location, Invite, and user models
  ViewModels/         Trip status, location, home, and auth view models
  Views/              Screens: create trip, on-trip, trip detail, home, profile
  Components/         Reusable UI: dynamic island, route progress, avatars, invitations
  Data/               TripStore and local data layer
  Resources/          Location and notification permission managers

OmaweWidget/          Live Activity / widget extension (ActivityKit)
Shared/               Types shared between the app and widget (OmaweWidgetAttributes)
OmaweTests/           Unit tests
```

## Requirements

- Xcode (latest stable)
- iOS 16.1+ (Live Activities require ActivityKit)
- An Apple Developer account for testing on-device location and Live Activities (the simulator has limited support for both)

## Getting started

1. Open `Omawe.xcodeproj` in Xcode.
2. Select the `Omawe` scheme and a physical iOS device (recommended, for real location + Live Activities behavior).
3. Build and run.

## Scope (v1)

Omawe v1 is iOS-only, built around Live Activities and ActivityKit. Android support, multi-stop trips, and persistent friend groups are being considered for later versions — see [`trip-tracker-prd.md`](trip-tracker-prd.md) for the full product spec, goals, and non-goals.

## Status

Actively in development. See recent commits for progress on Live Activities, trip editing, and haptic feedback.
