# PlaySnap MVP Implementation Plan

## 1. Goal

Build the smallest working version of PlaySnap that proves the core loop:

Capture -> upload -> squad sees it -> reacts -> poster is notified.

This plan assumes:

- iPhone-only MVP
- SwiftUI app
- Firebase backend
- One primary developer

## 2. Delivery strategy

Build in vertical slices, not isolated layers.

That means each milestone should produce something testable end to end, even if rough:

- auth that actually signs in
- squad flow that actually joins a squad
- camera flow that actually uploads
- feed that actually renders real data

## 3. Milestones

### Milestone 0: Project setup ✅ COMPLETE

Goal:
- Create a working Xcode project foundation

Tasks:
- ✅ Create iOS app target
- ✅ Create widget extension target
- ⚠️ Configure App Groups — entitlements added, capability must be toggled in Xcode Signing & Capabilities
- ✅ Add Firebase SDK dependencies
- ✅ Create Firebase project
- ✅ Add `GoogleService-Info.plist`
- ✅ Set up bundle identifiers
- ⚠️ Sign in with Apple — parked; requires paid Apple Developer account
- ⚠️ Push Notifications — skipped; requires paid Apple Developer account
- ✅ Set up basic app routing and environment injection

Done when:
- ✅ App launches on simulator/device
- ✅ Firebase initializes successfully
- ✅ Widget target builds

### Milestone 1: Auth and profile ✅ COMPLETE

Goal:
- Let a user sign in and complete a basic profile

Tasks:
- ✅ Build auth screen (email / password + phone)
- ⚠️ Sign in with Apple — parked until paid dev account is available
- ✅ Exchange credential with Firebase Auth
- ✅ Create `users/{uid}` document on first login via `FirebaseSessionDocumentStore`
- ✅ Build profile setup screen
- ✅ Save `name` and `primarySport` to Firestore
- ✅ Add session check on app launch (`restoreSession`)
- ✅ Route based on auth state and profile completion
- ✅ Enable Email/Password provider in Firebase Console
- ✅ Create Firestore database with auth rules in Firebase Console
- ✅ Test end-to-end on device: sign up → profile → main tab
- ⚠️ Avatar upload — deferred to profile edit in Milestone 9

Done when:
- ✅ User can sign in with email
- ✅ User profile persists after relaunch
- ✅ Returning user bypasses auth correctly

### Milestone 2: Squad creation and join flow ✅ COMPLETE

Goal:
- Get every user into exactly one squad

Tasks:
- ✅ Build squad setup screen
- ✅ Implement create squad flow
- ✅ Create squad document and member document (batch write)
- ✅ Update user with `squadID`
- ✅ Generate invite code (6-char, ambiguous chars removed)
- ✅ Build join by invite code flow
- ✅ Validate invite code
- ✅ Add join transaction (`FieldValue.arrayUnion` batch write)
- ✅ Handle invalid or expired code state (`SquadServiceError.invalidInviteCode`)
- ✅ Implement `FirebaseSquadService` (actor, backed by Firestore)

Done when:
- ✅ User can create a squad
- ✅ Another user can join with invite code
- ✅ Both users are members of the same squad in Firestore

### Milestone 3: Photo capture and upload ✅ COMPLETE

Goal:
- Make the camera usable and upload a photo end to end

Tasks:
- ✅ Build camera screen with AVFoundation live preview (`CameraPreviewView` UIViewRepresentable)
- ✅ Implement camera permissions flow (`CameraManager` + `NSCameraUsageDescription`)
- ✅ Capture photo (`AVCapturePhotoOutput` + `PhotoCaptureDelegate`)
- ✅ Compress image (`ImageCompressor.jpegData`)
- ✅ Upload to Firebase Storage (`squads/{squadID}/plays/{playID}/original.jpg`)
- ✅ Create `Play` document in Firestore (`FirebasePlayService.postPlay`)
- ✅ Return success state to UI (dismiss `CapturePreviewView` on post)
- ✅ Handle upload failure and retry UI (error message shown in `CapturePreviewView`)

Done when:
- ✅ User can open camera immediately after onboarding
- ✅ User can capture and send a photo
- Photo appears in Storage and Firestore (requires Firebase Storage rules update)

### Milestone 4: Feed and play detail ✅ COMPLETE

Goal:
- Let squad members see uploaded plays

Tasks:
- ✅ Build feed screen
- ✅ Subscribe to squad plays in reverse chronological order (`FirebasePlayService.fetchFeed`)
- ✅ Build play card UI with `AsyncImage`
- ✅ Build full-screen play detail view with `AsyncImage`
- ✅ Display image and metadata
- ✅ Add empty state for new squad
- ✅ Add loading and error states
- ✅ Auto-refresh on tab switch (`.onAppear`)

Done when:
- ✅ Squadmates see each other's plays in the feed
- ✅ Tapping a play opens the detail screen

### Milestone 5: Reactions ✅ COMPLETE

Goal:
- Add the simplest interaction loop

Tasks:
- ✅ Reaction write model in Firestore (reactions map: `userID → emoji`)
- ✅ Build emoji reaction UI (🔥 💪 👏 in `PlayCardView`)
- ✅ Prevent duplicate reactions per user
- ✅ Show current user's reaction state (highlighted button)
- ✅ Show reaction summary counts
- ✅ Optimistic local update via `FeedViewModel`

Done when:
- ✅ A user can react to a play
- ✅ The reaction is visible to other squad members

### Milestone 6: Push notifications ⚠️ PARKED

Goal:
- Notify users when the loop advances

Parked because:
- Requires paid Apple Developer account for push capability and APNs
- FCM Cloud Functions need a paid Firebase plan (Blaze)

### Milestone 7: Widget integration ✅ COMPLETE

Goal:
- Make the latest squad play visible on the home screen

Tasks:
- ✅ Define `WidgetPayload` model
- ✅ Build `AppGroupStore` (shared file container under `group.com.playsnapp.shared`)
- ✅ Write latest play payload after post (`CapturePreviewView` → `widgetSyncService`)
- ✅ Build widget timeline provider (`WidgetProvider`)
- ✅ Build widget entry view with `AsyncImage` + sender/sport overlay (`containerBackground` API)
- ✅ Reload widget timelines after post (`WidgetCenter.shared.reloadAllTimelines`)
- ✅ App Groups capability in both debug entitlements + release entitlements
- ✅ Fixed suite name mismatch (`playsnap` → `playsnapp`)
- ✅ Switched from `UserDefaults(suiteName:)` to `FileManager` container (avoids `cfprefsd` error)
- ✅ Switched to local thumbnail file (`latest_thumbnail.jpg` in App Group container via `AppGroupStore`) — avoids `AsyncImage` remote loading failures in widget sandbox
- ✅ `WidgetThumbnailRenderer` downsizes captured photo to 600px JPEG before saving
- ⚠️ Widget setup education screen — deferred to Milestone 9 polish

Done when:
- ✅ Widget renders the latest squad play photo after posting
- ✅ Widget handles empty state safely (shows gradient placeholder)

### Milestone 8: Video support

Goal:
- Add short video capture without breaking the core loop

Tasks:
- Record short video to temporary file
- Generate video thumbnail
- Upload video file
- Upload thumbnail
- Save video play metadata
- Delete temporary file after completion
- Render video plays in feed and detail screen
- Cap duration to 15 seconds

Done when:
- User can post a short video
- Feed and detail screens render video safely

### Milestone 10: Fair-play rotation tournament

Goal:
- Let a squad run a live session across multiple courts with fair rotation and a live billboard. Based on the JS prototype in `ideas.md` / conversation: sort roster by games played ascending, pick top `courts × 4`, pair into matches, update stats after each match.

Scope decisions (locked):
- **Doubles-only** (4 players/court). Feature is gated to squads whose sport is badminton / pickleball / tennis doubles. Hidden for other sports.
- One **organizer** device drives writes; other squad members get a read-only live view. Organizer = `session.createdBy`.
- A session is ephemeral (one evening of play), but per-session results **roll up into a permanent squad leaderboard** — see "Permanent leaderboard" below.
- Entry point: **button** on the feed or profile screen (not a new root tab), since sessions are occasional.

Permanent leaderboard:
- Separate collection: `squads/{squadID}/leaderboard/{userID}` with `{ totalPlayed, totalWins, totalLosses }`.
- When a match result is recorded, the Firestore transaction updates **both** the session doc AND the leaderboard entries for the 4 players (only for players with a real `userID` — guests are session-only).
- Billboard UI has a toggle: "This session" vs "All time".

Data model:

```
squads/{squadID}/tournaments/{sessionID}
  - createdAt, createdBy, status: "active" | "finished"
  - courts: Int
  - players: [{ userID?, name, played, wins, losses }]   // userID optional for guests
  - currentRound: [{ court, teamA: [name,name], teamB: [name,name] }]
  - history: [{ roundID, court, teamA, teamB, winnerTeam, endedAt }]
```

Domain layer:
- `TournamentSession`, `TournamentPlayer`, `TournamentMatch` models in `Domain/Models/`
- `TournamentServicing` protocol in `Domain/Services/`:
  - `createSession(squadID:, courts:, players:) async throws -> TournamentSession`
  - `generateRound(sessionID:) async throws -> [TournamentMatch]` — sort by `played` asc, random tiebreak, slice top `courts*4`, pair `[0,1] vs [2,3]`
  - `recordResult(sessionID:, match:, winnerTeam:) async throws` — increments played/wins/losses for the 4 players, appends to history
  - `observeSession(sessionID:) -> AsyncStream<TournamentSession>` — Firestore snapshot listener for the live billboard
  - `endSession(sessionID:) async throws`

Data layer:
- `StubTournamentService` for previews/tests (in-memory roster)
- `FirebaseTournamentService` (actor) using Firestore transactions for `recordResult` so stats updates are atomic

Feature layer (`Features/Tournament/`):
- `TournamentSetupView` — roster input (pull from squad members + add guests), court count stepper, "Start session" button. Validates `players.count >= 4`; warns if `players.count < courts*4` ("n players will sit out this round").
- `TournamentRoundView` — current round's matches grouped by court. Each match has a "Team A won" / "Team B won" button visible only to the organizer.
- `TournamentBillboardView` — roster sorted by wins desc, win-rate tiebreak. Shows played count + W/L.
- `TournamentViewModel` — holds observed session, exposes `generateNextRound`, `recordResult`.

Routing:
- Entry button on the feed or profile screen. Feature hidden unless `squad.sport ∈ {badminton, pickleball, tennis}`.

Tasks:
- Add Domain models + `TournamentServicing` protocol
- Implement rotation algorithm (pure function, unit-testable): input `[TournamentPlayer]` + `courts` → output `[TournamentMatch]` + `[sittingOut]`
- Unit tests: 30 players / 4 courts → 14 sit out; after round, those 14 are first picked next round
- Unit tests: billboard sort — wins primary, win-rate tiebreak, zero-played handled
- `StubTournamentService` + preview fixtures
- `FirebaseTournamentService` with Firestore transaction that updates session doc **and** leaderboard entries atomically
- Leaderboard collection + billboard toggle ("This session" / "All time")
- `TournamentSetupView`, `TournamentRoundView`, `TournamentBillboardView`
- `AppEnvironment` wiring (stub vs Firebase)
- Organizer vs viewer gating (compare `session.createdBy` to current user)
- Firestore security rule: only squad members can read; only `createdBy` can write match results

Done when:
- Organizer can start a session with N players and C courts
- Round 1 picks `C*4` players with lowest `played` count
- After recording a result, the next round prioritizes those who sat out
- All squad members see the live billboard update as matches are recorded
- Ending the session marks it `finished` and the UI exits back to the feed
- All-time billboard reflects the session's results after it ends

Risks / edge cases:
- Ties in `played`: random tiebreak is fine, but seed by last-round sit-out bias so the same person doesn't repeatedly sit out
- Network loss mid-result-record: Firestore transaction retries; UI should show "syncing" state
- Guest players (no `userID`): identified by name only — warn on duplicate names

### Milestone 9: Polish and beta readiness

Goal:
- Make the MVP stable enough for real users

Tasks:
- Add analytics events for core funnel
- Add crash reporting
- Improve loading states
- Improve retry paths
- Handle offline and poor network states
- Add sign-out flow
- Add profile edit flow
- Verify widget onboarding copy
- Prepare TestFlight metadata

Done when:
- Internal testers can use the app daily without critical failures

## 4. Build order summary

The practical order is:

1. Project setup
2. Auth and profile
3. Squad creation and join
4. Photo capture and upload
5. Feed and play detail
6. Reactions
7. Push notifications
8. Widget
9. Video
10. Polish
11. Fair-play rotation tournament

## 5. Current tickets (as of Milestone 7 in progress)

Milestones 0–6 are done (6 parked). Milestone 7 code is complete but blocked on device. Immediate next tickets:

1. **Unblock widget on device** — verify App Group checkmark in Xcode Signing & Capabilities for both targets, clean build, reinstall; test by posting a photo and checking the widget updates
2. **Milestone 8: Video capture** — AVFoundation video recording, 15s cap, thumbnail generation, upload `.mov` to Firebase Storage, write Play document with `mediaType: .video`
3. **Milestone 9: Polish** — sign-out flow, profile edit, loading/error state improvements, TestFlight prep

## 6. Recommended acceptance checks

Run these after each major milestone:

- New user can complete onboarding without manual database edits
- Returning user lands in the correct screen
- Two test accounts can join the same squad
- Posting from one device shows up on another device
- Reactions sync correctly between two devices
- Push notifications deep-link to the right screen
- Widget does not crash with empty data

## 7. Risks to manage early

These should be tested early, not left for the end:

- Camera startup speed
- Firebase auth setup on real device
- Push capability and token registration
- Widget data-sharing through App Groups
- Video temporary-file cleanup

## 8. What to cut if timeline slips

If development slows down, cut in this order:

1. Video support
2. Notifications screen
3. Avatar upload
4. Profile editing

Do not cut:

- auth
- squad membership
- photo posting
- feed
- reactions

## 9. Suggested timeline

For a solo MVP build:

- Week 1: project setup + auth
- Week 2: profile + squad flow
- Week 3: photo capture + upload
- Week 4: feed + play detail
- Week 5: reactions + push
- Week 6: widget
- Week 7: video
- Week 8: polish + TestFlight

## 10. Next step after this document

After the implementation plan, the next useful move is to start the actual codebase scaffold:

- create the folder structure
- create app target files
- set up Firebase initialization
- build the app router
