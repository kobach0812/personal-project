<div align="center">

# PlaySnapp

**A private sports social app for squads.**
Capture a play, share it instantly, and see it on your teammates' home‑screen widgets.

`iOS 26` · `SwiftUI` · `Swift 6 (strict concurrency)` · `Firebase`

</div>

---

## What it is

PlaySnapp is a camera‑first social app for small groups who play together — volleyball, basketball, badminton, pickup soccer. Snap a moment, it lands in your squad's feed and on their widgets, and your weekly games run themselves.

- **Camera‑first** — opens straight to the camera; one tap to capture and post
- **Squad feed** — a reverse‑chronological feed scoped to your active squad
- **Emoji reactions** — a lightweight interaction loop, no comment threads
- **Home‑screen widget** — the latest squad play, always visible (WidgetKit + App Groups)
- **Game tab** — organise play days with fair‑rotation matchmaking, fixed‑team round‑robins, and knockout brackets, plus a live billboard and match history across multiple sessions
- **Friends & squads** — a social graph for adding players by name, and multi‑squad membership

> **Naming:** the top‑level organiser entity is a **Game**. "**Tournament**" refers specifically to the knockout‑bracket sub‑tab inside a Game.

## Tech stack

| Area | Choice |
|---|---|
| UI | SwiftUI, Swift 6 strict concurrency |
| Backend | Firebase — Auth, Firestore, Storage, Messaging (push parked) |
| Media | AVFoundation capture; Firebase Storage upload (no on‑device media library) |
| Widget | WidgetKit + App Groups (device‑local thumbnail) |
| Deep links | custom URL scheme `playsnapp://` |
| Deployment target | iOS 26.4 (app), iOS 18.6 (widget) |

## Architecture

A protocol‑first, three‑layer design that keeps Firebase out of the domain and makes everything testable with in‑memory stubs.

- **Domain** — models + service protocols only (no SDK imports)
- **Data** — concrete `Firebase*` and `Stub*` implementations of those protocols
- **Features** — SwiftUI views + view models
- **`AppEnvironment`** injects every service; **`AppRouter`** drives navigation phases (`.auth` → `.onboarding` → `.squadSetup` → `.widgetIntro` → `.main`)

```
PlaySnapp/PlaySnapp/
├── App/                  # entry point, router, AppEnvironment (DI)
├── Domain/
│   ├── Models/           # Game, GameSession, GamePlayer, BracketTournament, …
│   └── Services/         # protocols + pure engines (GameRotationEngine, BracketEngine)
├── Data/
│   ├── Firebase/         # Firestore / Auth / Storage implementations
│   ├── Local/            # widget sync, onboarding flags
│   └── Stubs/            # in‑memory implementations for development + tests
├── Features/             # Auth · Onboarding · Camera · Feed · Friends · Profile · Tournament
├── Infrastructure/       # platform wrappers (camera)
├── Shared/
│   ├── Design/           # "Athletic Pro" design system — tokens + components
│   ├── Utilities/
│   └── Widget/           # App Group storage
└── PreviewSupport/       # fixtures + preview data only
```

## Getting started

1. **Clone** and open `PlaySnapp/PlaySnapp.xcodeproj` in Xcode 16+.
2. Add your **`GoogleService-Info.plist`** to the app target (it's git‑ignored, never committed).
3. In **Signing & Capabilities**, set your team and bundle ID.
4. Enable **App Groups** on both the app and widget targets using `group.com.playsnapp.shared`.
5. **Build & run** on a simulator or device.

> Firebase packages resolve automatically via Swift Package Manager on first build.

### Development mode (no Firebase needed)

`PlaySnapApp.swift` selects the data source:

```swift
@StateObject private var environment = AppEnvironment.bootstrap(dataSource: .firebasePrepared)
```

Switch `.firebasePrepared` → `.development` to run entirely on in‑memory stub data — no Firebase connection required.

## Testing

```bash
xcodebuild test -project PlaySnapp/PlaySnapp.xcodeproj -scheme PlaySnapp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PlaySnappTests
```

Tests use the **Swift Testing** framework (`import Testing`). The highest‑value coverage is the pure logic — `GameRotationEngine` (fair‑rotation matchmaking) and `BracketEngine` (group standings + knockout) — backed by stub service doubles. See [`docs/test-plan.md`](docs/test-plan.md).

## Project status

MVP milestones M0–M25 are complete or intentionally skipped:

| Range | Area | Status |
|---|---|---|
| M0–M9 | Setup, auth, squads, capture, feed, reactions, widget, polish | ✅ |
| M6 | Push notifications | ⚠️ parked (paid Apple Developer account) |
| M8 | Video | ⏸ deferred |
| M10–M14 | Game tab, friends, multi‑squad, multi‑session, invite links | ✅ |
| M15 / M16 | Weekly recap card / play streaks | ⏭ skipped |
| M17 | Participant self‑actions | 🔶 self‑bench done; score correction deferred |
| M18–M20 | Scheduled days + RSVP, tab refactor, fixed teams | ✅ |
| M21–M25 | Bracket "Tournaments" — group stage → knockout | ✅ |
| M26 | Recap suite — weekly + game day share cards | ✅ |
| M27–M29 | Play streaks, mascot, career stats | 📋 planned |

## Documentation

Deeper docs live in [`docs/`](docs/):

- [`product-spec.md`](docs/product-spec.md) — product specification
- [`technical-design.md`](docs/technical-design.md) — architecture, file map, Firestore schema
- [`implementation-plan.md`](docs/implementation-plan.md) — milestone history + changelog
- [`test-plan.md`](docs/test-plan.md) — testing strategy and inventory
- [`Design Ideas/`](docs/Design%20Ideas/) — visual direction ("Athletic Pro" lane)

## Conventions & key decisions

- **Squad‑scoped everything** — feed, posts, billboard, and games are always scoped to the active squad
- **Organizer‑only writes for a Game** — only the creator records results; others get a live read‑only view
- **Game‑level roster** — players (mutual **Friends** or named **Guests**) are added/removed at the Game level (⋯ menu); day sessions pick who plays from that roster
- **No on‑device media storage** — photos go straight to Firebase Storage; only a small (~600px) thumbnail is written to the App Group for the widget
