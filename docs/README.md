# PlaySnapp

A private sports social app for squads. Capture a play, share it instantly, and see it on your teammates' home screen widgets.

## What it does

- **Camera-first** — app opens directly to camera, one tap to capture and post
- **Squad feed** — reverse-chronological feed scoped to your active squad
- **Emoji reactions** — lightweight interaction loop without comments
- **Home screen widget** — latest squad play always visible on teammates' lock/home screens
- **Game tab** — organise fair-rotation play days, fixed-team round-robins, and knockout brackets, with a live billboard and match history across multi-session days
- **Friends** — social graph for adding players to a Game's roster without typing names

## Tech stack

- Swift + SwiftUI (iOS)
- Firebase Auth, Firestore, Firebase Storage, Firebase Messaging
- AVFoundation for camera capture
- WidgetKit + App Groups for home screen widget

## Project structure

```
PlaySnapp/
├── App/                        # entry point, router, environment
├── Domain/                     # models and service protocols (no Firebase)
│   ├── Models/
│   └── Services/
├── Data/                       # concrete service implementations
│   ├── Firebase/               # Firestore + Auth + Storage
│   ├── Local/                  # widget sync, onboarding flags
│   └── Stubs/                  # in-memory implementations for development
├── Features/                   # screens and view models
│   ├── Auth/
│   ├── Onboarding/
│   ├── Camera/
│   ├── Feed/
│   ├── Friends/
│   ├── Notifications/
│   ├── Profile/
│   └── Tournament/
├── Infrastructure/             # platform wrappers (camera)
├── Shared/                     # utilities and widget storage
│   ├── Utilities/
│   └── Widget/
└── PreviewSupport/             # fixtures and preview data only
```

## Setup

1. Clone the repo
2. Open `PlaySnapp/PlaySnapp.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the app target (not committed)
4. In Xcode → Signing & Capabilities, set your team and bundle ID
5. Enable **App Groups** on both the app target and widget target using `group.com.playsnapp.shared`
6. Build and run on simulator or device

> Firebase packages (Auth, Firestore, Storage, Messaging) are managed via Swift Package Manager and resolve automatically on first build.

## Running in development mode

`PlaySnapApp.swift` controls the data source:

```swift
@StateObject private var environment = AppEnvironment.bootstrap(dataSource: .firebasePrepared)
```

Change `.firebasePrepared` to `.development` to run with in-memory stub data (no Firebase connection required).

## Current milestone status

| Milestone | Description | Status |
|---|---|---|
| M0 | Project setup | ✅ Complete |
| M1 | Auth and profile | ✅ Complete |
| M2 | Squad creation and join | ✅ Complete |
| M3 | Photo capture and upload | ✅ Complete |
| M4 | Feed and play detail | ✅ Complete |
| M5 | Reactions | ✅ Complete |
| M6 | Push notifications | ⚠️ Parked (requires paid Apple Developer account) |
| M7 | Widget integration | ✅ Complete |
| M8 | Video support | ⏸ Deferred |
| M9 | Polish and beta readiness | ✅ Complete |
| M10 | Fair-play rotation game | ✅ Complete |
| M11 | Friends and social graph | ✅ Complete |
| M12 | Multi-squad membership | ✅ Complete |
| M13 | Multi-session Game + roster picker | ✅ Complete |
| M14 | Squad invite link + QR (deep link + share) | ✅ Complete |
| M15 | Weekly recap card (shareable image) | ⏭ Skipped |
| M16 | Play streaks | ⏭ Skipped |
| M17 | Participant self-actions (self-bench done; score correction deferred) | 🔶 Partial |
| M18 | Scheduled game days + RSVP + check-in | ✅ Complete |
| M19 | Game tab structural refactor (Game / Tournaments tabs) | ✅ Complete |
| M20 | Fixed teams in day sessions (round-robin) | ✅ Complete |
| M21–M25 | Bracket "Tournaments" sub-tab (groups → knockout brackets) | ✅ Complete |
| — | **Tournament→Game rename + game-level player management** | ✅ Complete |

## Key decisions

- **No on-device media storage** — photos upload directly to Firebase Storage; only a small widget thumbnail (~600px JPEG) is written to the App Group container
- **Squad-scoped everything** — feed, posts, leaderboard, and game sessions are always scoped to the user's active squad
- **Organizer-only writes for Game** — only the session creator can record match results; other participants get a live read-only view
- **Game-level roster** — players (mutual **Friends** or named **Guests**) are added/removed at the Game level via the ⋯ menu (Add Players / Remove from Game); day sessions select who plays from that roster rather than adding people inline
- **Guests in Games** — players without an account can be added by name; they appear in standings but do not get a live participant view
- **"Tournament" now means brackets only** — the top-level entity is a **Game**; "Tournament" is reserved for the knockout-bracket sub-tab inside a Game
