# PlaySnapp Test Plan

Comprehensive test plan covering M1–M25. Two upfront facts:

1. **Test target exists.** `PlaySnappTests` (Swift `Testing` framework, not XCTest) and `PlaySnappUITests` are both wired into `PlaySnapp.xcodeproj`. Stub doubles already live in `PlaySnappTests/TestDoubles.swift`.
2. **The architecture is unusually testable** — protocol-based services, pure engines, stub implementations for everything. Most of the value lives in pure-logic unit tests.

## 1. Tier model

| Tier | What | Tooling | Cost | Value |
|---|---|---|---|---|
| **1** | Pure logic units — engines, validators, builders | Swift `Testing`, no Firebase, no UI | Lowest | Highest |
| **2** | View model state machines | Swift `Testing` + stub services | Low | High |
| **3** | Service contract tests | Swift `Testing` + stubs | Medium | Medium |
| **4** | Manual scripts — camera, push, widget, multi-device | Real devices, written checklist | High | Hard to skip |

## 2. Scope rules

- ❌ Don't test Firebase service implementations directly — they're thin SDK wrappers; you'd be testing Firebase, not your code
- ❌ Don't set up Firebase Local Emulator until there's a CI pipeline that needs it
- ❌ Don't try to hit 80% coverage — chase the bugs that actually happen, not the percentage
- ❌ Don't write XCUITest — too slow and flaky to maintain solo; manual checklists are cheaper

## 3. Per-milestone test inventory

Listing only milestones with non-trivial test surface. **🔴 High = first pass.**

| M | Title | Priority | Tests |
|---|---|---|---|
| M2 | Squad create/join | Med | T1: invite code generator (6-char, no ambiguous chars). T3: stub squad create writes member doc + invite. T4: 2-device join. |
| M3 | Photo capture | Med | T1: `ImageCompressor.jpegData` size/quality bounds. T4: real device capture + upload. |
| M4 | Feed | Low | T2: `FeedViewModel` loading/error/empty states. |
| M5 | Reactions | Med | T1: reaction summary aggregation. T2: optimistic toggle. T3: dedup (one user → one reaction). |
| M7 | Widget | Med | T1: `WidgetThumbnailRenderer` 600px downsize. T1: `AppGroupStore` round-trip. T4: home screen install + post. |
| **M10** | **Rotation game** | **🔴 Highest** | T1: `GameRotationEngine` — historically buggy. Cases: 4p/1c no repeats, 5p/1c fair rest, 7p/2c, 8p/2c no concurrent partner repeats, 11p/2c, `applyResult` updates `lastPlayedAt`, partnership counter, benched player excluded, never-played priority. |
| M11 | Friends | Med | T1: `friendRequestID = from_to` determinism. T3: stub accept writes both directions. |
| M12 | Multi-squad | Med | T1: legacy `squadID` → `squadIDs[]` migration fallback. T2: active squad switcher. |
| M13 | Multi-session Game | Med | T1: `participantUserIDs` derivation. T2: `GameViewModel.role` (organizer / participant / spectator). |
| M14 | Invite link / QR | Med | T1: `playsnapp://join?code=XXX` URL parsing. T2: `AppRouter.handleInviteURL` per auth state. T4: Messages link cross-device. |
| M17 | Self-bench | Med | T1: bench state respected by rotation engine (extends M10). T4: 2-device bench → next match. |
| M18 | Scheduled days | Med | T1: `fetchNextScheduledSession` filter. T3: stub check-in mid-session adds to `players[]`. T4: 3-device host + RSVP + late check-in. |
| M20 | Fixed teams | Med | T1: `GameRotationEngine.generateFixedTeamRound`, `nextFixedTeamMatch`, `fixedTeamPlayCounts` (round-robin fairness). T2: mid-session mode switch doesn't interrupt current round. |
| **M21** | **Bracket backend** | **🔴 Highest** | T1: `BracketEngine` full coverage. `generateGroupMatches` count, `standings` sort, `startingRound` mapping, `pairInitialMatches` even + odd, `applySet` for best-of-1/3/5, `advanceBracketIfReady` for QF→SF→F+3rd→finished, 4-team & 2-team starting states. |
| M22 | Bracket setup UI | Low | T2: `CreateBracketSheet` validation (each group ≥ 2 teams). |

Milestones **not testable / skipped**: M0 (project setup), M1 (auth — covered by existing `AppRouterTests`), M6 (parked), M8 (deferred), M9 (visual polish), M15/M16 (skipped), M19 (refactor — covered by build).

## 4. Recommended starting point

**Start with the two engines.** Both are:

- Pure functions (zero side effects, zero SDK dependencies)
- Historically bug-prone (rotation had the Player-9 permanently-benched bug; bracket pairing is brand new and unverified in production)
- Quickest feedback loop — no Firebase, no UI, no setup

**Order:**

1. ✅ Test target — already exists (`PlaySnappTests`)
2. `GameRotationEngineTests.swift` — M10 + M17 + M20 coverage in one file (same engine)
3. `BracketEngineTests.swift` — M21 coverage
4. Once those land, expand to view models and Tier 3 stub contracts as time allows

## 5. Test fixtures

Centralize player / session / team builders in a `TestFixtures.swift` next to `TestDoubles.swift` so each test file stays focused on assertions. Keep IDs deterministic (`"p1"`, `"p2"`, …) where the test doesn't care about UUID randomness.

## 6. Engine coverage details

### GameRotationEngine (M10 / M17 / M20)

| # | Test | Asserts |
|---|---|---|
| 1 | 4 players / 1 court — first match | All 4 players assigned, no duplicates, court 1 |
| 2 | 5 players / 1 court — first match | 4 assigned, 1 left out |
| 3 | 7 players / 2 courts | Both courts filled, 1 player left out, no overlap |
| 4 | 8 players / 2 courts | Both courts filled, all 8 players, no overlap |
| 5 | 11 players / 2 courts | 8 assigned, 3 left out, no overlap |
| 6 | Never-played priority | A player with `played: 0` is picked before `played: 1` |
| 7 | Longest-rested priority | When all `played` equal, lower `lastPlayedAt` picked first |
| 8 | `applyResult` stamps `lastPlayedAt` | Winners and losers both get `lastPlayedAt = matchCounter` |
| 9 | `applyResult` wins/losses | Winner team += 1 win, loser team += 1 loss |
| 10 | `updatePartnerships` | Team `[a, b]` produces `partnerships[a][b] = 1`, symmetric |
| 11 | Benched player excluded | `isActive: false` player never appears in generated match |
| 12 | Fixed-team round generation | N teams → up to `min(N/2, courts)` matches, no team on two courts |
| 13 | Fixed-team least-played priority | Matchup played 0 times beats matchup played 1+ times |
| 14 | `nextFixedTeamMatch` respects busy courts | Returns nil when no valid matchup remains |

### BracketEngine (M21)

| # | Test | Asserts |
|---|---|---|
| 1 | `generateGroupMatches` for 2 teams | 1 match |
| 2 | `generateGroupMatches` for 4 teams | 6 matches, all pairs distinct |
| 3 | `generateGroupMatches` for 3 teams | 3 matches |
| 4 | `standings` sort by wins desc | Team with more wins ranks higher |
| 5 | `standings` tiebreak by losses asc | Equal wins → fewer losses ranks higher |
| 6 | `standings` tiebreak by point diff | Equal wins/losses → higher diff ranks higher |
| 7 | `startingRound` mapping | 2 → final, 3 → SF, 4 → SF, 5 → QF, 8 → QF, 9 → nil |
| 8 | `pairInitialMatches` even count | All matches have both teams, no bye |
| 9 | `pairInitialMatches` odd count | Last match has `teamBID = nil`, auto-completed |
| 10 | `setsToWin` | bestOf 1 → 1, bestOf 3 → 2, bestOf 5 → 3 |
| 11 | `applySet` best-of-3 winner | Two team-A wins → winnerTeamID set, completedAt stamped |
| 12 | `applySet` best-of-3 not yet decided | 1-1 → winnerTeamID nil |
| 13 | `advanceBracketIfReady` QF → SF | 4 completed QFs spawn 2 SF matches with correct teams |
| 14 | `advanceBracketIfReady` SF → Final + 3rd place | 2 completed SFs spawn Final + 3rd place |
| 15 | `advanceBracketIfReady` Final → finished | Completed Final flips bracket status to `.finished` |
| 16 | 4-team bracket starts at SF | `pairInitialMatches` produces 2 SF matches |
| 17 | 2-team bracket starts at Final | `pairInitialMatches` produces 1 Final match |

## 7. Out of scope for this plan

- Performance / load tests
- Snapshot tests of SwiftUI views
- Tests for the Firebase service implementations themselves
- CI configuration (set up later when shipping to TestFlight is unblocked)

## 5. Post-M25 changes (Tournament→Game rename + player management)

- **Naming:** the top-level entity is now **Game** (`GameModels`, `GameService`, `GameRotationEngine`, `GameViewModel`, `GameDetailView`, Firestore collection `games/`). The bracket sub-tab keeps "Tournament" (`BracketTournament*`).
- **New service method:** `removePlayer(playerID:from:)` on `GameServicing` (Firebase + Stub) — T3: stub removes from `game.players`, mid-session day copy untouched.
- **Player management moved to the Game level** (⋯ Add Players / Remove from Game); day sheets now only select from the existing roster. T2: `GameViewModel`/day-start selection no longer mutates the roster.
- **`BracketKnockoutSnapshotTests.swift`** renders the horizontal knockout tree (finished / live / start-with-placeholder states) to PNGs for visual eyeballing — render-only, not assertions.
