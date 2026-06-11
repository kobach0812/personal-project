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

### Milestone 10: Fair-play rotation tournament ("Game" tab)

Goal:
- Let a squad run a live session across multiple courts with fair rotation and a live billboard. Matches rotate **per-court independently**: when one court finishes, its next match is picked immediately (no waiting for the whole round).

Scope decisions (locked):
- **Doubles-only** (4 players/court). Feature is gated to squads whose sport is badminton / pickleball / tennis doubles.
- One **organizer** device drives writes; other squad members get a read-only live view. Organizer = `session.createdBy`.
- A session is ephemeral (one evening of play), but per-session results **roll up into a permanent squad leaderboard** — see "Permanent leaderboard" below.
- Entry point: **root "Game" tab** (camera / feed / game / alerts / profile). Moved from a feed-toolbar button on 2026-04-22 after testing showed sessions are frequent enough to deserve a tab.
- **Scoring:** win = 1 point, loss = 0 points. Billboard ranks by points desc, losses asc, then name. No draw handling.

Rotation algorithm (current implementation):
- Each player carries `lastPlayedAt: Int` — a stamp from a session-level `matchCounter` that increments on every completed match.
- When a court needs a new match, eligible pool = players NOT currently on any other court. Pool sorted by:
  1. `played` asc (never-played players go first)
  2. `lastPlayedAt` asc (longest-rested next)
  3. random tiebreak (explicit key, not sort-stability-dependent)
- Top 4 picked; team split chosen from 3 possible pairings (AB|CD, AC|BD, AD|BC) to minimize repeat partnerships. Ties broken randomly.
- `recordResult` increments `matchCounter`, stamps the 4 finished players' `lastPlayedAt`, removes the completed match, and immediately generates a new match for that court.
- Rest pattern emerges naturally: with 5 players / 1 court, the "play 1, rest 1" rotation happens because the rested player has lowest `lastPlayedAt`.

Permanent leaderboard:
- Separate collection: `squads/{squadID}/leaderboard/{userID}` with `{ totalPlayed, totalWins, totalLosses }`.
- When a match result is recorded, the Firestore transaction updates **both** the session doc AND the leaderboard entries for the 4 players (only for players with a real `userID` — guests are session-only).
- Billboard UI has a toggle: "This session" vs "All time".

Data model:

```
squads/{squadID}/tournaments/{sessionID}
  - createdAt, createdBy, status: "active" | "finished"
  - courts: Int
  - matchCounter: Int                                     // monotonic, increments per result
  - players: [{ id, userID?, name, played, wins, losses, lastPlayedAt }]
  - currentRound: [{ id, court, teamA: [id,id], teamB: [id,id], winnerTeam? }]
  - partnerships: { playerID: { partnerID: count } }      // for partner-rotation fairness
```

Status (as of 2026-05-02): ✅ COMPLETE
- Domain models, rotation engine, stub + Firebase services, setup/round/billboard views all shipped.
- `Game` tab wired into `MainTab` / `PlaySnapApp`. Trophy button removed from `FeedView`.
- Score entry (teamAScore/teamBScore) implemented via sheet on `MatchCard`.
- `completedMatches` tracked in-session and promoted to Firestore `matches` subcollection in M13.
- History tab shows completed matches with scores and timestamps.

### Score entry + match history ✅ COMPLETE

Goal:
- Organizer enters the actual score (e.g., 21–18) when recording a result — not just "Team A won".
- A new **History** tab inside the Game screen lists every completed match (court, teams, score, winner, time).
- Storage scope for now: **in-memory on the session only**. When the app quits or the session ends, history goes with it. Firebase persistence comes later.

Code changes:
- Extend `TournamentMatch` with `teamAScore: Int?` and `teamBScore: Int?` (optional — stays nil until result entered; scores are independent of `winnerTeam` so a manual override is possible).
- Add `completedMatches: [TournamentMatch]` to `TournamentSession`. Today `recordResult` *discards* the finished match when generating the next one for that court — change it to push to `completedMatches` first.
- `recordResult(for:matchID:winner:scoreA:scoreB:)` takes optional score args. Infer winner from scores if both provided and differ; otherwise use the explicit `winner`.
- UI: replace the "Team A Won / Team B Won" buttons on `MatchCard` with a sheet that takes two numeric inputs. Submit → `vm.recordResult(...)`.
- New `TournamentHistoryView` — a third tab inside `TournamentActiveView`'s `TabView` (Round / Board / **History**). Rows: `Court N · Team A 21 – 18 Team B · 8:43pm`. Tap for full player breakdown.
- `FirebaseTournamentService.recordResult` batch write stays unchanged for now — scores are client-only. `completedMatches` is **not** serialized until we promote this to Firebase.

Done when (for score+history slice):
- Organizer can enter two integer scores per match; billboard points update correctly (winner +1, loser +0).
- History tab shows every completed match for the current session with scores + timestamp.
- Killing the app and reopening loses history — acceptable for this milestone; explicit TODO in the code to persist later.

Later (Firebase promotion):
- Mirror `completedMatches` to a `matches` subcollection under the session doc.
- Security rule: only organizer writes; any squad member reads.
- Add a session recap view post-`endSession` that summarizes history.

---

Risks / edge cases:
- Network loss mid-result-record: Firestore transaction retries; UI should show "syncing" state
- Guest players (no `userID`): identified by name only — warn on duplicate names
- Score entry: reject negative numbers; allow tie scores but require explicit winner selection

### Milestone 9: Polish and beta readiness ✅ COMPLETE

Goal:
- Make the MVP stable enough for real users

Tasks:
- ✅ Sign-out flow — `ProfileViewModel.signOut` routes back to `.auth`; button uses `role: .destructive`
- ✅ Profile edit flow — `ProfileEditSheet` sheet; `ProfileViewModel.saveProfile` calls `updateProfile(name:)`; cancel/save/saving/error states
- ✅ Loading states — all views (`FeedView`, `NotificationsView`, `ProfileView`, `TournamentView`, `CameraView`) have proper loading, error, and empty states
- ✅ Retry paths — `FeedView` and `NotificationsView` have `.refreshable`; camera has Settings deep-link on permission denial
- ✅ Widget onboarding copy — `WidgetIntroView` exists and is routed from `AppRouter`
- ✅ Removed MVP placeholder notes from `ProfileView`
- ⚠️ Analytics events — deferred; requires a paid analytics service (Firebase Analytics or similar)
- ⚠️ Crash reporting — deferred; requires Firebase Crashlytics setup on a paid plan
- ⚠️ Offline/poor-network handling — basic error messages shown; proactive network monitoring deferred
- ⚠️ Avatar upload — deferred (UI needs `PhotosPicker` + `StorageServicing`; backend protocol ready)
- ⚠️ TestFlight metadata — deferred; requires paid Apple Developer account

Done when:
- ✅ Internal testers can sign in, post, react, view the feed, run a Game session, and sign out without critical failures

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

## 5. Current state (as of 2026-05-07)

Milestones 0–5, 7, 9–14, 18, 19, 20 complete. M17 partially complete (self-bench done; score correction deferred). Milestone 6 (push notifications) parked pending paid Apple Developer account. Milestone 8 (video) deferred. M15, M16 skipped by choice.

**Completed since last update:**
- M9: Sign-out, profile edit, loading/error states, widget onboarding
- M10: Fair-play rotation tournament, score entry, match history, leaderboard
- M11: Friends social graph (search, request, accept/decline, friends list)
- M12: Multi-squad membership, active squad switcher in Profile
- M13: Multi-session Game tab, `TournamentDetailView` session list, `StartDaySheet` with roster picker, `PlayerPickerSheet` (Squad / Friends / Guest tabs), day summary view for finished sessions, `matches` subcollection in Firestore, participant live view
- M14: Squad invite link (`playsnapp://join?code=XXX`), profile QR (`playsnapp://add?userID=XXX`), squad QR code sharing, `QRCodeGenerator`, `ProfileQRView`, `SquadQRView`
- M17 (partial): Participant self-bench toggle in Round tab — "Sit out this rotation" / "Re-enter rotation" button, writes `isActive` flag to Firestore via `setSelfBench`

**Bug fixes (2026-05-07):**
- Real-time session sync: `observeSession` Firestore snapshot listener added to `TournamentServicing` + Firebase implementation. All open devices update live when any device writes to the session doc
- Stale rotation bug (benched player still getting picked): `recordResult` now re-fetches fresh `players` array from Firestore before running the rotation engine, so bench changes from other devices are respected

**Remaining open work:**
- M6: Push notifications — blocked on paid Apple Developer account ($99/year)
- M8: Video capture and upload — deferred; requires temp file pipeline + thumbnail generation
- Avatar upload — backend protocol ready (`StorageServicing.uploadAvatar`); UI needs `PhotosPicker` wiring
- TestFlight submission — blocked on paid Apple Developer account
- Sign in with Apple — parked in `AppleSignInProvider.swift`; requires paid account + Push Notifications capability
- Score correction requests (M17 remainder) — deferred; Firestore write/read path needs debugging before re-implementing

**Completed since last update (cont.):**
- M18: Scheduled game days + RSVP + host check-in
  - `TournamentStatus` extended with `.scheduled` / `.cancelled`
  - `TournamentSession` gains `scheduledStart: Date?` and `location: String?`
  - `Registration` model (yes/maybe/no RSVP + host check-in stamp)
  - `ScheduleGameDaySheet` — host picks date/time/courts/location
  - `ScheduledDayDetailView` — RSVP buttons for all; check-in toggles for host only; "Start Session" auto-populates roster from checked-in registrations; late check-in mid-session adds player to rotation immediately
  - `ScheduledDayBanner` on Feed tab — shows today's scheduled game days
  - `Firestore: registrations/{userID}` subcollection with `observeRegistrations` real-time stream
  - `TournamentDetailView` updated: "Schedule Game Day" in ⋯ menu, smart session router (scheduled→ScheduledDayDetailView, active/finished→DayDetailView), updated DayRow shows date/location/status colour

**Next milestone candidates:**
- **M21**: Bracket Tournament backend — models, service, stub + Firebase
- **M22**: Bracket Tournament setup flow — create bracket UI
- **M23**: Bracket Tournament group round-robin — match scoring + live standings
- **M24**: Bracket Tournament configure knockout — advance count + best-of + random pairing
- **M25**: Bracket Tournament visual bracket — QF → SF → Final UI with set entry
- M17 remainder: Score correction requests (deferred; Firestore debug needed first)

**Future candidates (deferred or blocked):**
- Push notifications (blocked: paid Apple Developer account)
- Video support (deferred: storage cost, encoding pipeline)

---

### Milestone 11: Friends & social graph ✅ COMPLETE

Goal:
- Users can search for other PlaySnapp users by name and send a friend request. Once accepted, friends appear in each other's friend list and become candidates for squad invites and Game-session rosters (see Milestone 13).

**Implemented:**
- `Domain/Models/FriendModels.swift` — `Friend`, `FriendRequest`
- `Domain/Services/FriendService.swift` — `FriendServicing` protocol with `searchUsers`, `sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `fetchFriends`, `fetchPendingIncomingRequests`
- `Data/Stubs/StubFriendService.swift` — in-memory stub with 5 canned users; simulates request/accept/decline cycle
- `Data/Firebase/FirebaseFriendService.swift` — Firestore-backed actor; prefix search on `name`; `friendRequests/{fromUID_toUID}` pattern; accept writes both directions in one batch
- `Features/Friends/FriendsView.swift` + `FriendsViewModel` — search bar → results with Add button; pending requests section with Accept/Decline; friends list with empty state
- `FirestorePaths` additions: `friends(_:)`, `friend(_:_:)`, `friendRequest(_:)`
- Entry point: Profile → "Friends" NavigationLink
- `AppEnvironment.friendService` wired for both development (stub) and Firebase environments

**Deferred to follow-up:**
- `AsyncStream`-based real-time observers (current impl uses one-shot `async throws`; real-time upgrades in M14)
- Alerts-tab badge for incoming request count
- Cancel outgoing request
- Remove friend
- Block list

Scope decisions (locked):
- **Explicit handshake** (A sends → B accepts/declines). No auto-follow. Prevents spam and keeps the trust model clean.
- **Friends ≠ squad members.** A squad is a small fixed group; friends is your wider network. Friendship is the prerequisite for inviting someone to a squad or adding them to a Game session without typing their name.
- **No global / cross-squad feed.** Feed stays squad-scoped in MVP.
- **Search by display name only.** Prefix match, min 2 chars. No phone-contact import, no username handles in this milestone (deferred — handles can come later as a `usernameLower` field).
- **Symmetric friendship.** Accepting writes both `users/A/friends/B` and `users/B/friends/A` in a single transaction.
- **No block list in this milestone** — add a TODO; spam hasn't materialized yet.

#### 11.1 Data model (Firestore)

```
users/{userID}
  - name, nameLower (for prefix search), avatarURL?, createdAt, …
  - friendCount: Int             // denormalised counter, updated in transaction

friendRequests/{requestID}        // requestID = "{fromUserID}_{toUserID}" to dedupe
  - fromUserID, fromName, fromAvatarURL?
  - toUserID
  - status: "pending" | "accepted" | "declined" | "cancelled"
  - createdAt, updatedAt

users/{userID}/friends/{friendUserID}
  - name, avatarURL?             // snapshot (best-effort; refreshed on open)
  - addedAt: Timestamp
```

Indexes:
- `users` composite on `nameLower` ASC for prefix queries (`>= q && < q + "\uf8ff"`).
- `friendRequests` composite on `toUserID` + `status` + `createdAt DESC` for incoming list.

Why `requestID = from_to`: making the doc ID deterministic lets us block duplicate sends with a single `createIfAbsent`. Re-sending after decline is allowed by updating the same doc back to `pending`.

#### 11.2 Domain layer

Files (new):
- `Domain/Models/FriendModels.swift` — `FriendRequest`, `FriendRequestStatus`, `FriendSummary`.
- `Domain/Services/FriendService.swift` — `FriendServicing` protocol.
- `Data/Stubs/StubFriendService.swift` — in-memory for previews.
- `Data/Firebase/FirebaseFriendService.swift` — actor backed by Firestore.

`FriendServicing`:
```swift
protocol FriendServicing: Sendable {
    func searchUsers(query: String, limit: Int) async throws -> [AppUser]
    func sendRequest(to userID: String) async throws -> FriendRequest
    func cancelRequest(_ requestID: String) async throws
    func observeIncomingRequests() -> AsyncStream<[FriendRequest]>
    func observeOutgoingRequests() -> AsyncStream<[FriendRequest]>
    func respond(to requestID: String, accept: Bool) async throws
    func observeFriends() -> AsyncStream<[FriendSummary]>
    func removeFriend(_ userID: String) async throws
    func relationship(with userID: String) async throws -> FriendRelationship
}

enum FriendRelationship: Equatable {
    case none
    case requestSent(FriendRequest)
    case requestReceived(FriendRequest)
    case friends
    case self_
}
```

Transaction on accept (critical path):
1. Read `friendRequests/{id}`; assert `toUserID == currentUser && status == pending`.
2. Write `users/{from}/friends/{to}` and `users/{to}/friends/{from}` (both snapshots).
3. Update `status = accepted`, `updatedAt = now`.
4. Increment `friendCount` on both users.
All in one `runTransaction` so a half-accepted state is impossible.

#### 11.3 Feature layer (`Features/Friends/`)

New files:
- `FriendsView.swift` — list of friends, toolbar "Add", section header with incoming-request badge.
- `FriendRowView.swift` — name, avatar, trailing menu (Remove, Invite to squad, Add to session).
- `UserSearchView.swift` — search field + debounced results; each row shows state-aware button (`Add` / `Requested` / `Accept` / `Friends`).
- `FriendRequestsView.swift` — grouped list of incoming + outgoing; Accept / Decline / Cancel buttons.
- `FriendsViewModel.swift` — `@MainActor ObservableObject`; consumes the three `AsyncStream`s; debounces search at 250 ms.

Routing:
- Entry point: **Profile tab** → row "Friends" → `FriendsView`.
- Incoming request count surfaces as:
  - A badge on the **Alerts** tab (integrates with existing `NotificationsView`).
  - A "Requests (N)" banner at the top of `FriendsView`.

UI states to design:
- Empty (no friends) — CTA "Find your first friend".
- Search empty-result — "No users match '…'".
- Mid-send optimistic state — row shows spinner briefly.
- Request-received row on search result — renders Accept/Decline inline (skip second hop).

#### 11.4 Security rules (sketch)

```
match /users/{uid} {
  allow read: if request.auth != null;   // name + avatar only via projection
  allow write: if request.auth.uid == uid;
}
match /friendRequests/{reqID} {
  allow read: if request.auth.uid in [resource.data.fromUserID, resource.data.toUserID];
  allow create: if request.auth.uid == request.resource.data.fromUserID
                && request.resource.data.status == "pending";
  allow update: if request.auth.uid == resource.data.toUserID
                && resource.data.status == "pending"
                && request.resource.data.status in ["accepted", "declined"];
  // cancel by sender
  allow update: if request.auth.uid == resource.data.fromUserID
                && request.resource.data.status == "cancelled";
}
match /users/{uid}/friends/{friendID} {
  allow read: if request.auth.uid == uid;
  allow write: if false;   // only the accept-transaction (server-side validated) writes
}
```

Note: server-authoritative mutual write currently requires either (a) client-side transaction with a permissive rule allowing each user to write the *other's* friends doc only when a matching `accepted` request exists, or (b) a Cloud Function. Option (a) is fine for MVP; pick a rule like:

```
allow create: if exists(/databases/$(db)/documents/friendRequests/$(friendID + "_" + uid))
              && get(...).data.status == "accepted";
```

#### 11.5 Build order

1. Models + `FriendServicing` protocol + `StubFriendService` + previews.
2. `FriendsView` + `FriendsViewModel` wired to stub. Verify UI with canned data.
3. `FirebaseFriendService.searchUsers` + `sendRequest` + `UserSearchView`.
4. Incoming-request stream + Accept/Decline transaction.
5. Friends list stream + remove.
6. Security rules + manual 2-device QA.
7. Alerts-tab badge integration.

#### 11.6 Done when

- Two devices: A searches B by name, sends request, B sees it in Alerts + Friends, accepts.
- After accept, both users see each other in their `friends` subcollection and in the UI.
- Declining hides the request from both sides with no notification to the sender.
- Re-sending after decline is allowed (same doc flips back to `pending`).
- Removing a friend is symmetric and immediate.

#### 11.7 Open questions / deferred

- Usernames / handles (need uniqueness constraint; skip for MVP).
- Blocking / reporting.
- Friend-of-friend suggestions.
- Phone / contacts sync.

---

### Milestone 12: Multi-squad membership ✅ COMPLETE

Goal:
- A user can belong to multiple squads simultaneously (e.g., "Tuesday Pickleball", "Work Badminton"), switch between them fluidly, and each squad retains its own plays, leaderboard, and Game sessions. Squad membership decoupled from the user document.

**Implemented:**
- `AppUser.squadID` renamed to `activeSquadID`; `FirebaseSquadService` now writes `squadIDs` array union + `activeSquadID` on create/join; legacy `squadID` field read as fallback during migration
- `SquadServicing` extended with `fetchAllSquads()` and `setActiveSquad(id:)`
- `StubSquadService` tracks a list of squads; `fetchCurrentSquad` returns the one matching `activeSquadID`
- `ProfileView` — Squads section shows all squads with active-indicator checkmark; tap to switch; "Add a squad" → `AddSquadSheet` (create or join by code)
- `ProfileViewModel` — `allSquads`, `switchSquad`, `addSquad`; loaded concurrently with user profile
- `FirebasePlayService.requireUserAndSquad` reads `activeSquadID` with `squadID` migration fallback
- `AppFixtures.sampleUser` updated to `activeSquadID:`

**Deferred to follow-up (not blocking M13):**
- `users/{uid}/memberships/{squadID}` subcollection (richer per-squad state: role, joinedAt, unreadCount)
- `SquadContext` observable for reactive squad switching in Feed/Camera without reload
- Squad-switcher in main nav bar toolbar (currently Profile-only)
- `leaveSquad` flow
- Unread dot badges per squad

Motivation:
- Current model hard-codes `users/{uid}.squadID` as a single string. Real players belong to several groups. Forcing a single squad makes people leave-and-rejoin, destroying their leaderboard and history.

Scope decisions (locked):
- **No upper bound** on squad count per user for MVP (soft warn at 10).
- **"Active" squad** concept: the UI always has exactly one active squad selected — that drives Feed, Camera posts, Game tab default, widget, alerts. User switches via a picker in the toolbar.
- **Widget shows the active squad's latest play**, not a cross-squad merge. Simpler and matches user intent.
- **Posts belong to a squad, not to the user globally.** Same as today.
- **Leaderboard is per-squad.** No cross-squad aggregation.
- **Migration:** existing single-`squadID` users are seeded into the new membership collection on first launch of the new build. Keep the legacy field read-only for one release.

#### 12.1 Data model changes

Before:
```
users/{uid}
  - squadID: String   // single
```

After:
```
users/{uid}
  - activeSquadID: String?              // last-selected; UI default
  - squadIDs: [String]                  // denormalised list for quick gating (capped; truth is in /memberships)
  - // legacy squadID retained, read-only, one release

users/{uid}/memberships/{squadID}
  - squadID, name (snapshot), role: "owner" | "member"
  - joinedAt, lastOpenedAt
  - unreadCount: Int                    // drives red dots in the squad switcher

squads/{squadID}/members/{uid}          // already exists — unchanged
```

Why both `squadIDs` array and a subcollection: the array lets a single `users/{uid}` read power the squad picker without a second query; the subcollection holds richer per-squad state.

#### 12.2 Domain layer changes

- `AppUser.squadID: String?` → `activeSquadID: String?` + `squadIDs: [String]`.
- New `SquadMembership` model: `squadID`, `name`, `role`, `joinedAt`, `lastOpenedAt`, `unreadCount`.
- `SquadServicing` additions:
  - `observeMemberships(for userID: String) -> AsyncStream<[SquadMembership]>`
  - `setActiveSquad(_ squadID: String) async throws` — writes `users/{uid}.activeSquadID` + `lastOpenedAt`.
  - `leaveSquad(_ squadID: String) async throws` — removes membership + member doc; if it was active, pick another or fall back to Setup.
- `createSquad` and `joinByInviteCode` no longer block when user already has a squad; they append.

#### 12.3 App-wide routing changes

The single biggest change: most feature view models currently read `env.currentUser.squadID` once at load. They need to observe the **active squad ID** reactively.

Introduce a `SquadContext` (lightweight `@MainActor` `ObservableObject`) on `AppEnvironment`:
```swift
@MainActor
final class SquadContext: ObservableObject {
    @Published private(set) var active: SquadMembership?
    @Published private(set) var memberships: [SquadMembership] = []
    func switchTo(_ squadID: String) async { … }
}
```

Views that depend on a squad (`FeedView`, `TournamentView`, `CameraView`, `NotificationsView`, widget sync) subscribe to `squadContext.active`. Switching active squad triggers a `.task(id:)` refresh of each.

Router:
- `AppRouter.phase == .squadSetup` is shown only when `squadIDs.isEmpty`. After that, the user always lands in `.main`, with `activeSquadID` governing what they see.

UI:
- **Squad switcher** in the top-left of the main nav bar: avatar + squad name + chevron. Tap → sheet with list of memberships + "Create / Join another squad".
- Unread dots per squad (drives from `unreadCount`).
- Widget: after successful post, updates active squad's `AppGroupStore` slot. Widget timeline reads the slot keyed by `activeSquadID`.

#### 12.4 Migration plan

On first launch of the new build:
1. Read `users/{uid}`.
2. If `squadID` is present and `squadIDs` is empty: seed `squadIDs = [squadID]`, `activeSquadID = squadID`, and create `users/{uid}/memberships/{squadID}` from existing `squads/{squadID}/members/{uid}`.
3. Do NOT delete `squadID` yet. One release later, remove references + delete the field via a Cloud Function migration.

Rollback: if the new client reads a user with no `squadIDs` but a legacy `squadID`, treat them as single-squad (backfill lazily).

#### 12.5 Security rules changes

- `users/{uid}/memberships/{squadID}`: owner-read-write only.
- `squads/{squadID}/...`: existing rule `request.auth.uid in squad members` still holds; it does NOT need to change because membership check reads the `members` subcollection, not the user's array.

#### 12.6 Done when

- A user can create or join a second squad without leaving the first.
- Squad switcher lists all memberships; tapping switches Feed, Game, Camera, widget target.
- Widget shows the active squad's latest play after switching.
- Existing single-squad users migrate silently on first launch, no manual action.
- Leaving a squad works and, if it was active, falls back cleanly.

#### 12.7 Out of scope

- Cross-squad unified feed.
- Per-squad notification preferences (defer to Polish).
- Squad archiving / soft-delete.

---

### Milestone 13: Multi-session Game + roster-based player selection ✅ COMPLETE

Goal:
- Lift the Game tab from "one active session" to **many sessions per squad**, entered by roster rather than typed names, and make every added player a **participant** (not just a label on a card) so they can watch the schedule and scores live on their own device.

Motivation observed in testing:
- Typing 12 names every Tuesday is friction. Most players are already in the host's squad or friends list.
- Non-organizers currently have no read-only view of the running session. They ask "who's up next?" constantly. The data is in Firestore already — we just aren't rendering it for them.
- Squads run multiple sessions a week (different courts / venues). One-active-session is wrong.

Scope decisions (locked):
- **Sessions are first-class and listable.** A squad can have many `active` or `finished` sessions. "Game" tab opens to a list; tap into one, or create.
- **Organizer-only writes.** Participants read live. Same rule as today; just more readers.
- **Roster input** combines squad members + friends + "Quick add guest" (typed name, no account). Guests stay name-only.
- **Live view for participants** is real. They see: next match on every court, current match live, last 5 completed matches with scores, billboard.
- **No participant-side write actions in this milestone** (no self-scoring, no reaction, no "I'm sitting out"). That's Milestone 14.
- **Notifications** when you're up next is a stretch goal — gated on push infra landing.

Depends on: Milestone 11 (Friends) shipped; Milestone 12 (multi-squad) shipped or concurrent.

#### 13.1 Data model changes

Current:
```
squads/{squadID}/tournaments/{sessionID}    // one "active" at a time enforced in UI
  - players: [{ id, userID?, name, ... }]
  - currentRound: [...]                     // in-memory rotation state
  - completedMatches: [...]                 // client-only today
```

Changes:

```
squads/{squadID}/tournaments/{sessionID}
  - title: String                     // "Tuesday 8pm", editable
  - status: "active" | "finished"
  - createdBy, createdAt, endedAt?
  - courts: Int
  - players: [TournamentPlayer]       // same shape; userID always set for roster-added entries
  - currentRound, matchCounter, partnerships  // unchanged
  - participantUserIDs: [String]      // denormalised for security rule + query

squads/{squadID}/tournaments/{sessionID}/matches/{matchID}   // NEW
  - court, teamA, teamB
  - teamAScore?, teamBScore?, winnerTeam
  - completedAt
  - recordedBy: String (organizer uid)
```

Why a real `matches` subcollection: `completedMatches` is currently an in-memory array on the session doc. That works for the organizer but is invisible to participants and is lost when the app quits. Promoting to a subcollection makes it:
- Queryable: participants can stream "latest 20".
- Persistent: survives app kill, device switch.
- Cheaper than embedding all matches in the session doc as it grows.

#### 13.2 Domain layer changes

- `TournamentSession.title: String`, `endedAt: Date?`, `participantUserIDs: [String]`.
- `TournamentMatch` gains `recordedBy: String`.
- `TournamentServicing` additions:
  - `observeSessions(squadID: String) -> AsyncStream<[TournamentSession]>` — list view for Game tab.
  - `observeSession(squadID: String, sessionID: String) -> AsyncStream<TournamentSession>` — live read for participants.
  - `observeMatches(squadID: String, sessionID: String, limit: Int) -> AsyncStream<[TournamentMatch]>` — history, newest first.
  - `recordResult(...)` writes to the `matches` subcollection AND updates the session doc atomically (single batch).
  - `endSession(sessionID:)` flips status, stamps `endedAt`.
- Rotation engine unchanged.

#### 13.3 Roster picker

New UI component `PlayerPickerSheet`:
- Three tabs: **Squad** · **Friends** · **Guest**.
- Squad / Friends tabs: multi-select list; search bar; selected count shown; "Add N players" button.
- Guest tab: text field + Add (existing behaviour). Warn on duplicate names across the session.
- Selected players appear as chips above the picker; tap X to remove before confirming.

`TournamentSetupView` changes:
- "Add players" CTA opens `PlayerPickerSheet` instead of inline text field.
- A player row shows a small badge: 🟢 squad / 👥 friend / 👤 guest.
- `TournamentPlayer.userID` is set for squad/friend rows. This enables the participant-live-view (13.5).

`FriendServicing` / `SquadServicing` must expose cached lists (already present for squad members).

#### 13.4 Sessions list view (Game tab landing)

Replace current "jump to active if exists, else setup" logic with:

- `GameSessionListView` — segmented control **Active | Past** + "New Session" button in toolbar.
- Active row: title, courts, N players, live indicator if anyone's on court. Tap → `TournamentView(sessionID:)`.
- Past row: title, final standings glimpse (top 3), date. Tap → read-only recap.
- Empty state: "Start your first session".

`TournamentView` becomes `TournamentView(sessionID:)` — always driven by an ID, never by "the active session".

#### 13.5 Participant live view

Problem: today, non-organizer users can't even open a session. We need the same `TournamentActiveView` (Round / Board / History tabs) but with writes disabled when `currentUser.uid != session.createdBy`.

Implementation:
- `TournamentViewModel.role: { .organizer, .participant, .spectator }` — computed from `session.createdBy`, `session.participantUserIDs`, and the current user.
- `MatchCard` and billboard hide score-entry UI when `role != .organizer`.
- Round tab shows a "You're up next on Court 2" banner when the current user's `userID` appears in any `currentRound` match.
- History tab streams from the new `matches` subcollection (not from in-memory `completedMatches`).

Security rules:
```
match /squads/{sid}/tournaments/{tid} {
  allow read: if request.auth.uid in resource.data.participantUserIDs
              || isSquadMember(sid);
  allow write: if request.auth.uid == resource.data.createdBy;
}
match /squads/{sid}/tournaments/{tid}/matches/{mid} {
  allow read: if request.auth.uid in get(/…/tournaments/$(tid)).data.participantUserIDs
              || isSquadMember(sid);
  allow create: if request.auth.uid == get(/…/tournaments/$(tid)).data.createdBy;
}
```

(Squad members can read even if not in roster — useful for spectators from the sideline.)

#### 13.6 Score entry changes

Extend the existing score-entry sheet (already planned in Milestone 10) to:
1. Take `teamAScore`, `teamBScore`, derive `winnerTeam`.
2. Write a new doc to `matches/{matchID}` with `recordedBy = currentUser.uid`.
3. In the same batch, update session's `currentRound`, `matchCounter`, player `lastPlayedAt`, and leaderboard deltas.

`TournamentSession.completedMatches` is removed from the model — history is now the `matches` subcollection. This is a breaking change; migration is trivial (abandoned sessions pre-migration just lose client-only history, which was already the case).

#### 13.7 Build order

1. Promote `matches` to a subcollection. Keep single-active-session assumption. Verify organizer + Firebase round-trip.
2. `observeSession` + `observeMatches` streams. Wire a read-only `TournamentView` as a second consumer on the organizer's device (sanity check).
3. `GameSessionListView`; allow creating more than one `active` session per squad; make session-ID explicit in routing.
4. `PlayerPickerSheet`; wire Friends + Squad sources; keep guest fallback.
5. Security rules + 2-device QA: organizer on device A, participant on device B.
6. "You're up next" banner.
7. Past-sessions tab + recap view.

#### 13.8 Done when

- A squad can have multiple sessions running in parallel (e.g., two courts at two venues).
- Creating a session opens a roster picker with squad + friends + guest tabs; typing is the fallback, not the default.
- Added participants open the Game tab, see the session, and view live: current matches, next-up on each court, billboard, and the last N completed matches with scores.
- Organizer-only score entry is enforced both in UI and by security rules.
- Killing the app and reopening preserves the match history (it's in Firestore now).
- Finishing a session moves it to the Past tab with a recap.

#### 13.9 Out of scope / follow-ups

- Participant self-check-in ("I'm here / I'm leaving early").
- Participant-side score submission with organizer approval.
- Session templates ("usual Tuesday crew").
- Push notifications when you're up next (needs M6 push infra).
- Cross-squad sessions (guest squad vs home squad) — explicit no.

---

### Milestone 14: Squad invite link 📋 PLANNED

Goal:
- Replace "tell your friend the 6-char code over text" with a tappable link. Onboarding a new squad member should be one tap, not three steps.

Motivation:
- Current join flow requires the inviter to recite an `inviteCode` and the invitee to type it into the join screen. Every character of friction loses people. The squad already has the code; we just need to wrap it in a URL and a Share button.
- Growth is currently blocked by join friction. This is the single highest-leverage non-paid feature.

Scope decisions (locked):
- **Custom URL scheme** (`playsnapp://join?code=ABC123`) for MVP. Works without a paid Apple Developer account, no AASA file, no domain hosting. Universal Links (`https://playsnap.app/join?code=...`) deferred until a real domain + paid account exists.
- **No new server state.** The invite code already lives on `squads/{squadID}.inviteCode`. The link is a thin client wrapper around it.
- **No expiring links** in this milestone. Codes are stable per squad. Rotating-code support is a follow-up.
- **No referral tracking.** We don't record who invited whom. (Could be added later by appending `&from=userID` to the link.)

#### 14.1 Domain layer changes

None. `Squad.inviteCode` already exists; this milestone consumes it.

#### 14.2 Data layer changes

None. No Firestore reads or writes added.

#### 14.3 App layer changes

`Info.plist`:
- Add `CFBundleURLTypes` entry registering the `playsnapp` scheme.

`PlaySnapApp.swift`:
- Add `.onOpenURL { url in router.handleInviteURL(url) }` to the root scene.

`AppRouter.swift`:
- Add `@Published var pendingInviteCode: String?`.
- Add `func handleInviteURL(_ url: URL)`:
  - Parse `playsnapp://join?code=XXX`. If valid, store `pendingInviteCode = code`.
  - If user is unauthenticated → set phase to `.auth`; the code persists through auth/profile setup.
  - If user is authenticated and has no squad → route to `.squadSetup` with code prefilled.
  - If user is in a squad → route to a "Join another squad?" confirmation (multi-squad is M12-supported), then prefill the join field.

#### 14.4 Feature layer changes

`Features/Profile/ProfileView.swift` (Squads section):
- Add a Share button next to each squad row. Tap → `ShareLink(item: SquadInvite(...))` with a pre-formatted message:
  ```
  Join my squad "Tuesday Pickleball" on PlaySnapp:
  playsnapp://join?code=ABC123
  ```
- Define `SquadInvite: Transferable` (or use `String`) — produces both the link and a fallback text.

`Features/Squad/SquadJoinView.swift` (or wherever the join code field lives):
- Accept an optional `prefilledCode: String?` initializer parameter.
- On appear, if `pendingInviteCode` exists in the router, populate the field and (optionally) auto-submit after a 1.5s delay so the user sees what's happening.
- After successful join, clear `router.pendingInviteCode`.

#### 14.5 Build order

1. Register URL scheme in `Info.plist`. Verify `xcrun simctl openurl booted "playsnapp://join?code=TEST"` prints something in `handleInviteURL`.
2. Add `pendingInviteCode` flow in `AppRouter`. Manually verify routing through auth → join.
3. Add `ShareLink` to Profile squads section. Test that tapping the shared link from Messages opens the app.
4. Wire prefill into the join screen.
5. Manual two-device QA: A taps share, sends to B via Messages; B taps link → installs/opens app → joins squad.

#### 14.6 Done when

- A user can tap "Share invite" on any squad and send a link via Messages, Mail, or any share extension.
- A recipient who already has the app installed taps the link → app opens directly to the join flow with the code prefilled.
- A recipient who is unauthenticated still gets the code held until they finish auth + profile setup.
- The original Squad code-typing flow still works for users who receive only the code.

#### 14.7 Out of scope / follow-ups

- Universal Links (`https://...`) — needs domain + paid account.
- Expiring or revocable codes.
- Referral tracking (who invited whom).
- QR code rendering for in-person sharing.

---

### Milestone 15: Weekly recap card 📋 PLANNED

Goal:
- Auto-generate a beautiful, shareable image summarizing the squad's week. Users post it to Instagram / iMessage / their group chat. The image leaves the app and pulls non-users back to the squad link.

Motivation:
- Every retention feature compounds against current users only. A recap card is one of the few features that creates *outbound* visibility — every share is potential acquisition.
- Aggregation is local (filter feed by date); no backend change needed.

Scope decisions (locked):
- **Pure client-side derivation** from the existing feed. No new Firestore collection, no Cloud Functions.
- **One canonical layout** in the first version. No themes, no customization. Ship one beautiful card.
- **Window: last 7 days**, ending today. Not "last calendar week". Simpler and always fresh.
- **Includes**: squad name, date range, play count, reaction count, top reactor (display name), top play thumbnail.
- **Render via `ImageRenderer`** (SwiftUI 4+, iOS 16+). Same view used both for in-app preview and the rendered image — single source of truth.
- **Entry**: a "📊 Recap" button in `FeedView` toolbar. Tap → preview sheet with `ShareLink` to the rendered PNG.

#### 15.1 Domain layer changes

New file `Domain/Models/SquadRecap.swift`:
```swift
struct SquadRecap: Equatable {
    let squadName: String
    let weekStart: Date
    let weekEnd: Date
    let playCount: Int
    let reactionCount: Int
    let topReactorName: String?
    let topPlay: Play?
}
```

No new protocol. The recap is derived, not fetched.

#### 15.2 Shared utility

New file `Shared/Utilities/SquadRecapBuilder.swift`:
- `static func build(plays: [Play], squad: Squad, now: Date = .now) -> SquadRecap`
- Pure function. Easy to unit test.
- Filters plays where `createdAt >= now - 7d`. Sums `reactionSummary` values for the count. Picks the play with the highest reaction sum as `topPlay`. Picks the user with the most reactions given (best-effort: requires a small per-user tally; if that's expensive, defer to "top play poster").

#### 15.3 Feature layer

New folder `Features/Recap/`:
- `WeeklyRecapView.swift` — the visual card. Designed to look good both in-app and as a 1080×1920 image. Uses `Squad`, `SquadRecap`, and renders the top play thumbnail via `AsyncImage`.
- `WeeklyRecapViewModel.swift` — `@MainActor` `ObservableObject`. Loads plays via `playService.fetchFeed()`, builds the `SquadRecap`, exposes `state: .loading / .ready / .empty / .error`.
- `WeeklyRecapSheet.swift` — wraps the card in a sheet with a `ShareLink` that exports the rendered image.

`Features/Feed/FeedView.swift`:
- Add a single toolbar button: `Button { showRecap = true } label: { Image(systemName: "chart.bar.doc.horizontal") }`.
- Sheet presentation only — no other Feed changes.

#### 15.4 Image rendering

```swift
@MainActor
func renderRecapImage(_ recap: SquadRecap, squad: Squad) -> UIImage? {
    let renderer = ImageRenderer(content: WeeklyRecapView(recap: recap, squad: squad).frame(width: 1080, height: 1920))
    renderer.scale = 3
    return renderer.uiImage
}
```

`ShareLink` accepts the `UIImage` (wrap in a `Transferable` adapter or use the built-in `Image` overload).

#### 15.5 Edge cases

- **No plays this week** → empty state in the sheet: "No plays yet — post one to start your recap." No share button shown.
- **Top play has no thumbnail** → fall back to a sport-themed gradient placeholder (matches widget empty state).
- **Top reactor tie** → pick first by name (deterministic).
- **Image render returns nil** (rare) → show a "Couldn't generate recap" error with retry.

#### 15.6 Build order

1. `SquadRecap` model + `SquadRecapBuilder` pure function. Unit test with fixture plays.
2. `WeeklyRecapView` — visual layout. Iterate in Xcode preview with fixture data.
3. `WeeklyRecapSheet` + `WeeklyRecapViewModel` — wire to live data.
4. Toolbar entry on `FeedView`.
5. `ShareLink` integration. Manual test: share to Messages, verify image quality.

#### 15.7 Done when

- A user opens the Feed, taps Recap, sees a card summarizing their squad's last 7 days.
- The Share button exports a high-resolution PNG to any share extension.
- Empty state is handled (no plays this week).
- The card is visually distinct enough to be recognizable as PlaySnapp content when shared.

#### 15.8 Out of scope / follow-ups

- Multiple themes / customization.
- Monthly / season recaps.
- Auto-prompt to share at end-of-week (push notification).
- Per-user year-in-review.
- Animated recap (Stories format).

---

### Milestone 16: Play streaks 📋 PLANNED

Goal:
- Show "🔥 5 day streak" on the Feed when the squad has posted on consecutive days. One counter, zero new infrastructure, surprisingly addictive.

Motivation:
- Streaks are the cheapest retention mechanic in mobile apps (Snapchat, Duolingo). They cost almost nothing to build and create a daily-return habit.
- Pure local computation — like the recap, derives from already-fetched feed.

Scope decisions (locked):
- **Squad-level streak**, not per-user. The unit of social cohesion in PlaySnapp is the squad. A single member posting keeps the streak alive.
- **Day boundary = local timezone midnight.** Simple and matches user mental model.
- **Computed locally on every feed load.** No persistence required — the feed itself is the source of truth.
- **Streak breaks at >24h gap between posts.** Visualized as: any calendar date with zero plays breaks the streak.
- **No retroactive streak preservation.** If a streak breaks, it resets to 0. No "streak freeze" tokens, no leniency.
- **No celebration animations** in v1. Just the number and the flame. Keep it cheap.

#### 16.1 Domain layer changes

New file `Domain/Models/SquadStreak.swift`:
```swift
struct SquadStreak: Equatable {
    let currentStreak: Int    // 0 if today has no posts AND yesterday didn't either
    let isLiveToday: Bool     // true if a post was made today (the streak is "warm")
    let lastPostDate: Date?
}
```

#### 16.2 Shared utility

New file `Shared/Utilities/StreakCalculator.swift`:
- `static func compute(plays: [Play], now: Date = .now, calendar: Calendar = .current) -> SquadStreak`
- Pure function:
  1. Group plays by `Calendar.startOfDay(for:)` of `createdAt`.
  2. Walk backwards from today: if today has plays → `isLiveToday = true`; start counting consecutive days with plays.
  3. If today has no plays but yesterday does → still on streak (will break if no post today by midnight).
  4. Stop at the first gap.
- Easy to unit test with fixture dates.

#### 16.3 Feature layer

`Features/Feed/FeedView.swift`:
- Add a small badge to the feed header (above the play list, below the navigation title):
  - If `streak.currentStreak >= 2` → show `🔥 {N} day streak`.
  - If `streak.currentStreak < 2` → hide the badge entirely (don't shame users).
  - If `isLiveToday == false && currentStreak >= 2` → show `🔥 {N} days · post today to keep it!` (one gentle nudge).
- The badge is read-only display — no tap action in v1.

`Features/Feed/FeedViewModel.swift`:
- After `fetchFeed()` succeeds, compute `streak = StreakCalculator.compute(plays: ...)`.
- Expose `@Published var streak: SquadStreak?`.

#### 16.4 Widget (stretch — gate on time)

If trivial: extend `WidgetPayload` with `streakDays: Int?` and render a small "🔥 5" badge in the widget corner. Gate this behind a separate sub-task; the in-app badge ships first.

#### 16.5 Edge cases

- **Empty feed** → `currentStreak = 0`, badge hidden.
- **All plays today** → `currentStreak = 1`. Badge hidden until at least 2 days (avoid spamming "1 day streak" on first post).
- **Plays in the future** (clock skew) → ignore future-dated plays in the calculation.
- **Multi-squad** → the streak is for the *active* squad only. Switching squads recomputes.

#### 16.6 Build order

1. `SquadStreak` model + `StreakCalculator` pure function. Unit tests with these fixtures:
   - Empty feed → 0
   - Posts today only → 1, isLiveToday = true
   - Posts today + yesterday → 2
   - Posts today + 2 days ago (gap yesterday) → 1
   - Posts every day for a week → 7
2. Wire into `FeedViewModel`.
3. Add badge to `FeedView`.
4. Manual QA: post a play, kill app, reopen → badge shows. Skip a day in code → badge resets.
5. (Optional) Widget integration.

#### 16.7 Done when

- After two consecutive days of posting, the Feed shows "🔥 2 day streak".
- The number ticks up correctly each day a post is made.
- A skipped day resets the counter to 0.
- The badge disappears cleanly when streak < 2.
- Switching to a squad that has no streak hides the badge.

#### 16.8 Out of scope / follow-ups

- Per-user streaks ("you personally posted 3 days in a row").
- Streak freezes / pauses.
- Push notifications when a streak is at risk (blocked on M6).
- Badges or rewards for milestones (10 days, 30 days, etc.).
- Streak sharing as a recap card.

---

---

### Milestone 17: Participant self-actions 📋 PLANNED

Goal:
- Give participants (non-organizer roster members) two simple write-actions in a live Game session: **mark themselves benched/active** ("I'm sitting this one out" / "I'm back in") and **request a score correction** on a completed match. Today only the organizer can write — every adjustment goes through them, which is friction at every court.

Motivation observed in testing:
- Players step out for water, a phone call, or to leave early. Today they have to physically tell the organizer, who has to find them in the player list and toggle their bench state. Most organizers just don't do it, so the rotation ships them new matches they can't play.
- Score-entry mistakes happen (wrong court tapped, transposed digits). Currently the only fix path is "yell across the gym at the organizer". A lightweight in-app correction request closes the loop.
- M13 already established the participant live view and the `role` distinction. M17 is the natural next step — turn the read-only live view into a *minimally* writable one.

Scope decisions (locked):
- **Two actions only**: self-bench toggle, and score-correction request. No self-scoring of new matches, no organizer-impersonation, no roster edits. Keep the surface area small.
- **Self-bench is direct.** A participant toggling their own `isActive` writes immediately — no organizer approval. The rotation respects it on the next match generation. Same data path the organizer already uses; security rule just allows the *self* row.
- **Score correction is a request, not a write.** Participant submits "Court 2, match at 7:43pm — I think it was 21–18, not 18–21". Organizer sees a small inbox in the live session view; they Approve (apply the change) or Dismiss. No automatic correction. Preserves organizer authority.
- **Guests cannot self-act.** Self-actions require `userID`. Guests stay name-only, organizer-managed.
- **No history of dismissed requests.** Resolved requests are deleted. Avoids building a moderation surface.
- **No notifications** in this milestone. Organizer sees the inbox count next time they open the session. M6 unblocks push later.

Depends on: M13 (multi-session Game + roster + live view) shipped.

#### 17.1 Data model changes

`TournamentPlayer` — no shape change. The existing `isActive: Bool` flag is the bench state.

New subcollection:
```
squads/{squadID}/tournaments/{tournamentID}/sessions/{sessionID}/correctionRequests/{requestID}
  - matchID: String
  - requestedBy: String           // userID of the participant
  - requestedByName: String       // snapshot for organizer UI
  - proposedScoreA: Int
  - proposedScoreB: Int
  - proposedWinner: WinnerTeam    // derived if scores differ; explicit if tie
  - note: String?                 // optional one-line "tapped wrong court"
  - createdAt: Timestamp
  - status: "pending"             // only pending docs exist; resolved → deleted
```

Why a subcollection rather than a field on the match: corrections are rare, transient, and resolution removes them. A subcollection keeps the match doc small and avoids contention when multiple participants request at once.

Why the doc disappears on resolve (vs. flipping to `approved`/`dismissed`): in MVP we don't need an audit log. Less code, fewer rules.

#### 17.2 Domain layer changes

`TournamentServicing` additions:

```swift
// MARK: - Participant self-actions

/// Sets the calling user's own isActive flag for the session.
/// Server enforces caller.uid == player.userID.
func setSelfBench(isActive: Bool, in session: TournamentSession) async throws -> TournamentSession

/// Submits a score-correction request for a completed match.
/// Server enforces caller.uid is in session.participantUserIDs.
func submitCorrectionRequest(_ request: CorrectionRequest, for session: TournamentSession) async throws

/// Organizer-only: stream of pending correction requests for the session.
func observeCorrectionRequests(for session: TournamentSession) -> AsyncStream<[CorrectionRequest]>

/// Organizer-only: applies the requested score, updates the match doc, recomputes
/// player win/loss/leaderboard if the winner changed, then deletes the request doc — all in one batch.
func approveCorrectionRequest(_ request: CorrectionRequest, for session: TournamentSession) async throws -> TournamentSession

/// Organizer-only: deletes the request doc without applying it.
func dismissCorrectionRequest(_ request: CorrectionRequest) async throws
```

New file `Domain/Models/CorrectionRequest.swift`:
```swift
struct CorrectionRequest: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let matchID: String
    let requestedBy: String
    let requestedByName: String
    var proposedScoreA: Int
    var proposedScoreB: Int
    var proposedWinner: WinnerTeam
    var note: String?
    let createdAt: Date
}
```

#### 17.3 Data layer changes

`StubTournamentService`:
- In-memory dictionary keyed by sessionID → list of `CorrectionRequest`.
- `setSelfBench` flips the player's `isActive` and returns the updated session.
- `approveCorrectionRequest` mirrors `recordResult` logic for the override case (winner flip → swap wins/losses on the four players).

`FirebaseTournamentService`:
- `setSelfBench`: single-field update on `players[index].isActive` via array rewrite (existing pattern in `updatePlayers`).
- `submitCorrectionRequest`: `addDocument` to the new subcollection.
- `observeCorrectionRequests`: snapshot listener wrapped in `AsyncStream`.
- `approveCorrectionRequest`: batch write — update the match doc in `matches/{matchID}`, update affected players' wins/losses/lastPlayedAt if the winner flipped, update the leaderboard deltas, delete the request doc.
- `dismissCorrectionRequest`: single delete.

`FirestorePaths` additions: `correctionRequests(_:_:_:)`, `correctionRequest(_:_:_:_:)`.

#### 17.4 Feature layer changes

`Features/Tournament/TournamentViewModel.swift`:
- Add `pendingCorrectionRequests: [CorrectionRequest]` (organizer view).
- Add `selfBenchToggle()` — calls `setSelfBench` for the current user.
- Add `submitCorrection(matchID:scoreA:scoreB:note:)`.
- Add `approve(_:)` and `dismiss(_:)` for the organizer.

`Features/Tournament/TournamentActiveView.swift` (or wherever the role-aware live view lives):
- **Participant Round tab**: above the "You're up next on Court N" banner, add a small toolbar button:
  - If `currentUser.isActive` → "I'm sitting out" (taps → confirm sheet → `selfBenchToggle()`).
  - If not active → "I'm back in" button.
- **Participant History tab**: each completed match row gains a tappable "…" menu → "Request correction" → opens `CorrectionRequestSheet` with the existing scores prefilled.
- **Organizer view**: a new icon button in the toolbar with a badge showing `pendingCorrectionRequests.count`. Tap → `CorrectionInboxView` listing each pending request with Approve / Dismiss.

New files:
- `Features/Tournament/CorrectionRequestSheet.swift` — two number fields + optional note + Submit.
- `Features/Tournament/CorrectionInboxView.swift` — list of pending requests; rows show match summary + proposed change diff.

#### 17.5 Security rules

```
match /squads/{sid}/tournaments/{tid}/sessions/{ssid} {
  allow update: if request.auth.uid == resource.data.createdBy
                || (
                    // self-bench: participant toggling only their own player row
                    request.auth.uid in resource.data.participantUserIDs
                    && onlyOwnPlayerActiveFieldChanged()
                );
}

match /squads/{sid}/tournaments/{tid}/sessions/{ssid}/correctionRequests/{rid} {
  allow read: if request.auth.uid in get(/…/sessions/$(ssid)).data.participantUserIDs
              || request.auth.uid == get(/…/sessions/$(ssid)).data.createdBy;
  allow create: if request.auth.uid == request.resource.data.requestedBy
                && request.auth.uid in get(/…/sessions/$(ssid)).data.participantUserIDs;
  allow delete: if request.auth.uid == get(/…/sessions/$(ssid)).data.createdBy
                || request.auth.uid == resource.data.requestedBy;
}

match /squads/{sid}/tournaments/{tid}/sessions/{ssid}/matches/{mid} {
  // existing organizer-only write rule unchanged — corrections still go through organizer approval
}
```

The `onlyOwnPlayerActiveFieldChanged()` helper: compare `request.resource.data.players` to `resource.data.players` and assert exactly one element differs, only in `isActive`, and that element's `userID == request.auth.uid`. Implemented as a Firestore rule function.

If that helper is too gnarly to express in rules, fallback: store `isActive` in a per-player subcollection (`sessions/{ssid}/playerStates/{userID}`) instead of inlined in `players[]`. Cleaner rule, costs one extra read on session load. Decide during build step 1.

#### 17.6 Build order

1. **Self-bench, stub-only.** Add `setSelfBench` to `TournamentServicing` + `StubTournamentService`. Wire UI toggle in participant Round tab. Verify rotation respects `isActive` (already does — `recomputeReachableTiles`-equivalent logic in `TournamentRotationEngine` already filters inactive players).
2. **Self-bench, Firebase + rules.** Implement `setSelfBench` in `FirebaseTournamentService`. Pick the rules approach (inline-array vs subcollection) and write the matching security rules. 2-device QA.
3. **Correction request submission.** Add subcollection model + stub + Firebase create. Add `CorrectionRequestSheet` to participant History tab.
4. **Organizer inbox.** Add `observeCorrectionRequests` stream + `CorrectionInboxView` + toolbar badge.
5. **Approve / dismiss.** Implement the batched write that flips the match result, recomputes leaderboard deltas, and deletes the request. Edge case: organizer approves while player has already played another match — the `lastPlayedAt` stamps stay (only wins/losses flip).
6. **2-device QA.** Organizer on A, participant on B. Bench → unbench → submit correction → organizer approves → all clients see the corrected score.

#### 17.7 Done when

- A participant can mark themselves benched without bothering the organizer; rotation skips them on the next round.
- A participant can request a score correction on any completed match; the organizer sees a clear diff and one-tap approve/dismiss.
- Approving correctly updates: the match doc, both teams' player win/loss totals, `lastPlayedAt` stamps unchanged, leaderboard deltas applied, request doc deleted.
- Dismissing simply deletes the request — no notification, no record.
- Security rules block: a participant from editing another player's `isActive`, a non-participant from creating a correction request, anyone from writing the match doc directly.
- Killing and reopening the app preserves all of the above (Firestore-backed).

#### 17.8 Out of scope / follow-ups

- Self-scoring (a participant submitting the result of a fresh match) — much harder consensus problem, defer.
- Notifications when a correction request lands or is resolved — needs M6 push.
- Audit log of resolved corrections.
- Multi-step approval (e.g., both teams' captains must agree) — over-engineered for friend-group play.
- Participant-initiated "I have to leave entirely" (which would clear them from the roster, not just bench). Current bench-toggle is sufficient; full removal stays organizer-only.

---

---

### Milestone 18: Scheduled game days + RSVP + host check-in 📋 PLANNED

Goal:
- Let the host schedule a game day in advance ("Tuesday 8pm, 2 courts"). Squad members RSVP themselves. On the day, **the host marks each arriving player as checked in** by tapping their name in the registration list. The roster for the running session is auto-populated from check-ins, not from typing names. The host can also check players in *after* the session is already running, and the late arrivals join the rotation immediately.

Motivation:
- Today the Game tab is reactive: someone shows up at the gym, opens the app, taps "New session", types names. This wastes the network effect — nobody knows a session is happening unless they're already there.
- Scheduling forward turns the Game tab into a reason to *open* the app: "Am I going Tuesday?" "Who's confirmed?" "When does it start?". That's a recurring habitual visit no other surface in the app currently triggers.
- Host-driven check-in collapses the current "type each name" friction into a single-tap toggle on the pre-existing RSVP list. The host stops being a name-typist.
- Late check-in (the explicit requirement): once the session is `active`, the host tapping a player's check-in toggle appends them to the roster mid-session. The rotation engine already gives `lastPlayedAt = 0` players priority, so they're naturally up next.

Scope decisions (locked):
- **RSVP is self-service. Check-in is host-only.** Squad members RSVP themselves (Yes / Maybe / No). Only the host (`session.createdBy`) can mark someone as checked in. Players cannot check themselves in — this prevents fake or accidental check-ins, mirrors the M10 organizer-writes-only philosophy, and removes all the security-rule complexity around participant-writes-to-`players[]`.
- **One-off scheduled days only** in v1. No recurring events (defer to v2 — handle "every Tuesday" via duplicate-and-edit until demand justifies more).
- **No max-capacity / waitlist** in v1. Display registration count; don't gate. (Defer cap + waitlist.)
- **No reminders or push notifications** — blocked on M6. Compensate with a Feed banner ("📅 Game tonight at 8pm — 5 confirmed").
- **Squad-scoped only.** Friends-not-in-squad can't be invited to a scheduled day in v1. They join via the existing M13 roster picker once the session is `active`. (Reasoning: keeps the registration list bounded to the squad's member set, simplifies security rules.)
- **Guests stay host-managed.** No userID = no self-RSVP. Host adds guests via the existing roster picker at session start, same as today.
- **Host always counts as checked-in.** When the host taps "Start session", they're added to the roster automatically — no need to RSVP or check themselves in.
- **Cancellation is allowed and visible.** Cancelled days stay in the list with a `cancelled` badge for one week, then disappear. (Don't silently delete — people who RSVPed deserve to see "this got cancelled".)
- **No editing time after RSVPs exist** in v1. To change time, host cancels and reschedules. (Defer the "edit and notify everyone" flow.)

Depends on: M13 (multi-session Game + roster) shipped. Pairs naturally with M17 (self-bench reuses the same self-write pattern).

#### 18.1 Data model changes

`TournamentSession` — extend the existing `status` enum:
```swift
enum TournamentStatus: String, Codable, Sendable {
    case scheduled    // NEW — exists in advance, no roster yet
    case active       // existing — currently being played
    case finished     // existing
    case cancelled    // NEW — host cancelled before it started
}
```

New fields on `TournamentSession`:
```swift
var scheduledStart: Date?        // nil for legacy/walk-up sessions; set for scheduled days
var location: String?            // free-text, optional ("Court 3, Eastern Park")
```

Why nullable `scheduledStart`: existing sessions (M13) were created walk-up style. New flow sets it. Old data stays valid.

New subcollection:
```
squads/{squadID}/tournaments/{tournamentID}/sessions/{sessionID}/registrations/{userID}
  - userID, name, avatarURL?
  - status: "yes" | "maybe" | "no"           // self-written by the participant
  - registeredAt: Timestamp
  - checkedInAt: Timestamp?                  // host-written. nil = host hasn't checked them in
  - checkedInBy: String?                     // host's userID (audit trail)
  - addedToRoster: Bool                      // true once they've been pulled into players[]
```

Single doc per user, doc ID = userID (dedupe). `status` captures the planning intent (self-written by the registrant); `checkedInAt` captures the host marking them present (host-only write); `addedToRoster` prevents double-adding when the host checks someone in mid-session.

Why both `checkedInAt` AND `addedToRoster`: the host might check a player in *before* tapping Start, in which case we just stamp `checkedInAt` and the player is materialized into `players[]` only when Start runs. After the session is `active`, checking someone in does both writes in one batch. `addedToRoster` is the idempotency guard.

#### 18.2 Domain layer changes

`TournamentServicing` additions:

```swift
// MARK: - Scheduled day lifecycle

/// Creates a session in `scheduled` status. No roster yet.
func scheduleSession(
    in tournament: Tournament,
    title: String,
    scheduledStart: Date,
    courts: Int,
    location: String?
) async throws -> TournamentSession

/// Host-only. Cancels a scheduled day before it starts.
func cancelScheduledSession(_ session: TournamentSession) async throws -> TournamentSession

/// Host-only. Transitions scheduled → active and seeds players from currently-checked-in registrations.
func startScheduledSession(_ session: TournamentSession) async throws -> TournamentSession

// MARK: - RSVP (participant self-action)

/// Self-only. The current user sets their own RSVP (yes / maybe / no).
/// Creates the registration doc if missing.
func setRegistrationStatus(
    _ status: RegistrationStatus,
    for session: TournamentSession
) async throws

// MARK: - Check-in (host-only)

/// Host-only. Idempotent. Stamps checkedInAt for the given user.
/// If session is `active`, also appends them to players[] and flips addedToRoster in one batch.
/// If session is `scheduled`, just stamps checkedInAt — the player is materialized into the
/// roster when the host taps Start.
/// Allowed for any squad member, even one who hasn't RSVPed (creates the registration doc on the fly).
func checkInPlayer(userID: String, in session: TournamentSession) async throws -> TournamentSession

/// Host-only. Reverses a check-in. Only allowed if the player has not yet been added to the roster
/// (i.e., session still `scheduled` OR `addedToRoster == false`). Once a player is in the rotation,
/// removal goes through the existing roster-edit path, not check-in undo.
func undoCheckIn(userID: String, in session: TournamentSession) async throws

func observeRegistrations(for session: TournamentSession) -> AsyncStream<[Registration]>

/// Host-only. Removes someone's registration entirely. Doesn't touch the roster if they were already added.
func removeRegistration(_ registration: Registration, from session: TournamentSession) async throws
```

New file `Domain/Models/Registration.swift`:
```swift
enum RegistrationStatus: String, Codable, Sendable {
    case yes
    case maybe
    case no
}

struct Registration: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String              // == userID
    let userID: String
    var name: String
    var avatarURL: URL?
    var status: RegistrationStatus
    let registeredAt: Date
    var checkedInAt: Date?
    var addedToRoster: Bool
}
```

#### 18.3 Data layer changes

`StubTournamentService`:
- New `[sessionID: [Registration]]` dictionary.
- `scheduleSession` creates a session with empty `players`, status `scheduled`, the given `scheduledStart`.
- `setRegistrationStatus` upserts the registration doc for the calling user.
- `checkInPlayer` stamps `checkedInAt = .now`, `checkedInBy = currentUserID`. If session is `active`, also calls existing `addPlayers([TournamentPlayer(...)], to:)` and flips `addedToRoster`.
- `undoCheckIn` clears `checkedInAt` / `checkedInBy` if `addedToRoster == false`; throws otherwise.
- `startScheduledSession` filters registrations where `checkedInAt != nil`, maps them to `TournamentPlayer`, sets `addedToRoster = true` on each, transitions session to `active`.

`FirebaseTournamentService`:
- `scheduleSession` — single `setData` on the new session doc.
- `setRegistrationStatus` — `setData(merge: true)` on `registrations/{uid}` for the *calling* user only.
- `checkInPlayer` — batch: stamp `checkedInAt` + `checkedInBy` on `registrations/{userID}` (creating the doc if missing — covers walk-up squad members who never RSVPed). **If** session is `active`, append to `players` array on session doc + flip `addedToRoster`. **Else** just the stamp.
- `undoCheckIn` — single update clearing `checkedInAt` / `checkedInBy`, gated on `addedToRoster == false`.
- `startScheduledSession` — transaction: read all registrations with `checkedInAt != nil`, build `players[]`, write session with `status = active` and `players` populated, batch-flip `addedToRoster = true` on those registrations.
- `observeRegistrations` — snapshot listener wrapped in `AsyncStream`.

`FirestorePaths`: `registrations(_:_:_:)`, `registration(_:_:_:_:)`.

#### 18.4 Feature layer changes

**Game tab landing:**
- Add a third segment to the existing `Active | Past` control: `Upcoming | Active | Past`.
- `Upcoming` = sessions with `status == .scheduled` (or `.cancelled` within last 7 days), sorted by `scheduledStart` ascending.
- Each row shows: title, date/time, location (if set), `N registered · M checked in`, host name.

**New files in `Features/Tournament/`:**

- `ScheduleGameDaySheet.swift` — date picker (default: today + 1 day, evening), time picker, courts stepper, optional location text field, title field (default: "Game day"). Single CTA: "Schedule".
- `ScheduledDayDetailView.swift` — header with date/time/location, registration list grouped by status (Going / Maybe / Not coming).
  - **For all squad members:** RSVP buttons at top (Yes / Maybe / No).
  - **For the host only:** each registration row has a tappable check-in toggle (⬜ → ✅) and an "Add walk-up" button at the bottom of the list that opens a sheet listing remaining squad members who haven't registered. Tap a name to mark them checked in.
  - **For the host only:** "Start session" button (enabled when `now >= scheduledStart - 30min` OR always available with confirm), "Cancel" / "Edit" actions.
  - Each registered user has a check-in indicator (✅ checked in / ⏳ awaiting).
- `ScheduledDayBanner.swift` — informational banner shown on **Feed tab** when there's a scheduled session today: "📅 Game tonight at 8pm — 5 going". Tap → opens `ScheduledDayDetailView`. No check-in CTA in the banner since players can't self-check-in.

**Existing file edits:**

- `Features/Tournament/TournamentView.swift` — handle `status == .scheduled` by routing to `ScheduledDayDetailView` instead of `TournamentActiveView`. Handle `.cancelled` with a read-only banner.
- `Features/Tournament/TournamentViewModel.swift` — add `registrations: [Registration]`, `myRegistration: Registration?`, `isHost: Bool`, `setRSVP(_:)`, `hostCheckIn(userID:)`, `hostUndoCheckIn(userID:)`, `startSessionTapped()`, `cancelSessionTapped()`.
- `Features/Feed/FeedView.swift` — show `ScheduledDayBanner` at top when `nextScheduledSession?.scheduledStart` is within today.
- `Features/Feed/FeedViewModel.swift` — query `tournamentService` for the next scheduled session of the active squad on Feed appear.

**Late check-in path** (the user's explicit requirement, host-driven):
- Frank shows up 20 minutes after Alice tapped "Start session". The session is now `active`. Alice opens the session detail.
- Alice sees Frank's registration row with the ⬜ check-in toggle. She taps it → `checkInPlayer(userID: frank, ...)` runs the `active`-branch: stamps `checkedInAt`, appends Frank to `players[]` with `played: 0, lastPlayedAt: 0`. Next round generation picks him first.
- If Frank *never* RSVPed but is a squad member, Alice taps "Add walk-up" → picks Frank from the squad-member list → same code path runs (registration doc created on the fly with `status = yes, checkedInAt = .now`, then materialized into the roster).
- If Frank is not a squad member at all, the existing M13 roster picker (Friends tab / Guest tab) is the path — unchanged from today.

#### 18.5 Security rules

Host-only check-in keeps the rule shape clean. There is **no participant self-write to `session.players[]`** anywhere — that path was the rule-complexity risk and it's been designed out.

```
match /squads/{sid}/tournaments/{tid}/sessions/{ssid} {
  allow read: if isSquadMember(sid);
  // Only the host writes the session doc — no exception for participants.
  allow write: if request.auth.uid == resource.data.createdBy;
}

match /squads/{sid}/tournaments/{tid}/sessions/{ssid}/registrations/{uid} {
  allow read: if isSquadMember(sid);

  // Self can write status / registeredAt only — never checkedInAt or addedToRoster.
  allow create: if request.auth.uid == uid
                && request.resource.data.userID == uid
                && request.resource.data.checkedInAt == null
                && request.resource.data.addedToRoster == false;

  allow update: if request.auth.uid == uid
                && onlyRSVPFieldsChanged()   // status, name, avatarURL only
                || request.auth.uid == get(/…/sessions/$(ssid)).data.createdBy;
  // Host can also CREATE a registration on behalf of a walk-up squad member
  // (squad-member-only — friends-not-in-squad use the existing roster picker).
  allow create: if request.auth.uid == get(/…/sessions/$(ssid)).data.createdBy
                && isSquadMember(sid);

  allow delete: if request.auth.uid == get(/…/sessions/$(ssid)).data.createdBy;
}
```

`onlyRSVPFieldsChanged()` is a small rule helper that compares the diff of changed fields against the allow-list `{status, name, avatarURL}`. Any attempt by a non-host to flip `checkedInAt`, `checkedInBy`, or `addedToRoster` is rejected at the rule layer.

This is the same shape as the existing M10 organizer-writes-only rule — no new patterns introduced.

#### 18.6 Build order

1. **Domain models + status extension.** Add `scheduled`/`cancelled` cases, `scheduledStart`, `location`, `Registration` model. Migrate existing call sites that switch on `status` (currently exhaustive on `active`/`finished`).
2. **Stub-only schedule + RSVP + host check-in.** Implement `scheduleSession`, `setRegistrationStatus`, `checkInPlayer`, `undoCheckIn`, `startScheduledSession` in `StubTournamentService`. Build `ScheduleGameDaySheet` + `ScheduledDayDetailView` using stubs (with both host and non-host modes). Verify the full flow in previews.
3. **Firebase + rules.** Implement the same in `FirebaseTournamentService`. Write the host-only rules (clean — no participant-writes-to-players concern).
4. **Game tab Upcoming segment.** Wire the third segment, route scheduled rows to detail.
5. **Feed banner.** `ScheduledDayBanner` on Feed when a scheduled session exists today (informational only).
6. **Late check-in path.** End-to-end QA with three devices: host (A) starts session, then mid-session checks in registered player (B) and walk-up player (C). Both should appear in the rotation, prioritized by `lastPlayedAt = 0`.
7. **Cancellation.** Host taps Cancel, status flips, all registered users see `.cancelled` badge in Upcoming.

#### 18.7 Done when

- Host can schedule a game day with date, time, courts, optional location.
- Squad members can see upcoming days in the Game tab and tap to RSVP themselves (Yes / Maybe / No).
- Players cannot check themselves in — the check-in toggle on each registration row is visible and tappable only when `currentUser.uid == session.createdBy`. Security rules reject any non-host write attempt.
- The Feed shows an informational banner when a scheduled session is happening today.
- On the day, the host taps the check-in toggle next to each arriving player. The host's "Start session" button then populates the roster from checked-in registrations automatically.
- Mid-session check-ins (host taps a player's toggle after Start) immediately add them to the rotation, with rotation priority preserved (`lastPlayedAt = 0` ⇒ next match).
- Walk-up check-ins (host adds a squad member who never RSVPed) work via "Add walk-up".
- Host can cancel a scheduled day; the cancelled status is visible to RSVPed users.
- Killing and reopening the app preserves all of the above.

#### 18.8 Out of scope / follow-ups

- **Self check-in.** Explicitly excluded — only the host checks players in. Reconsider only if hosts complain about tap-fatigue at large sessions (12+ players). If revisited, the cleanest path is a Cloud Function that watches `registrations.checkedInAt` writes, gated to `request.auth.uid == registration.userID`, and only the function itself touches `session.players[]`. Until then: host-only, full stop.
- Recurring events ("every Tuesday 8pm").
- Reminders / push notifications (blocked on M6).
- Capacity caps + waitlist.
- Editing a scheduled day's time after RSVPs exist (host must cancel + reschedule).
- Inviting friends-not-in-squad to a scheduled day (use M13 roster picker at session start instead).
- Cross-squad scheduled days.
- Calendar integration (export to iOS Calendar / Google Calendar).

---

### Milestone 19: Game tab structural refactor ✅ COMPLETE

Goal:
- Lay the foundation for M20+ by restructuring the Game tab. Small, non-breaking change. No new functionality.

Tasks:
- Rename Game tab navigation title from "Tournaments" to "Game"
- Add a third tab segment inside `TournamentDetailView`: `Board / Days / Tournaments`
- The new "Tournaments" tab shows an empty placeholder (`ContentUnavailableView`) — populated in M21+

Files:
- Edit `TournamentView.swift` — rename navigation title
- Edit `TournamentDetailView.swift` — add 3rd tab segment + placeholder content

Done when:
- Game tab top header reads "Game"
- Inside any tournament, three tabs are visible: Board, Days, Tournaments
- Tournaments tab shows "No bracket tournaments yet" empty state

---

### Milestone 20: Fixed Teams within day sessions 📋 PLANNED

Goal:
- Allow the host to define fixed pairs at session start (e.g., Alice + Bob always play together). Replaces fair-play rotation with round-robin between fixed teams. Used in casual leagues where partnerships are pre-arranged.

Scope:
- New mode picker on `StartDaySheet`: **Rotation** (existing) vs **Fixed Teams** (new)
- Fixed Teams mode: host adds teams (name + 2 players each); round-robin schedule generated
- `MatchCard` and billboard show team names instead of individual player rows
- Score entry and result recording unchanged (winner = team that won)
- No mid-session mode switching

Data model:
```swift
enum SessionMode: String, Codable, Sendable {
    case rotation
    case fixedTeams
}

struct FixedTeam: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var playerIDs: [String]   // exactly 2 player IDs
}

// TournamentSession additions:
var mode: SessionMode
var fixedTeams: [FixedTeam]
```

New files (1):
- `Domain/Services/FixedTeamMatchGenerator.swift` — pure round-robin scheduler

Edited files (5):
- `Domain/Models/TournamentModels.swift` — `SessionMode`, `FixedTeam`, session field additions
- `Features/Tournament/TournamentDetailView.swift` (`StartDaySheet`) — mode picker + team builder UI
- `Features/Tournament/TournamentRoundView.swift` (`MatchCard`) — team name display when `mode == .fixedTeams`
- `Features/Tournament/TournamentBillboardView.swift` — team-based standings
- `Data/Firebase/FirebaseTournamentService.swift` + `Data/Stubs/StubTournamentService.swift` — serialize/deserialize new fields, branch on `mode` in `recordResult`

Done when:
- Host can pick Fixed Teams mode and define N teams of 2 players each
- Round-robin generates: every team plays every other team
- Billboard ranks teams (not individuals) by W/L
- Existing Rotation mode unchanged

---

### Milestone 21: Bracket Tournament — backend layer 📋 PLANNED

Goal:
- Establish data layer for bracket tournaments. No UI yet. Sets up the foundation for M22–M25.

Scope:
- New domain models, service protocol, stub + Firebase implementations, Firestore paths
- A "Bracket Tournament" lives nested inside an existing `Tournament` (subcollection: `tournaments/{tournamentID}/brackets/{bracketID}`)
- Phases: `setup → groupStage → configuringKnockout → knockout → finished`

Data model:
```swift
struct BracketTournament: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let parentTournamentID: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    var title: String
    var status: BracketStatus
    var groups: [BracketGroup]
    var knockoutBestOf: Int        // set when knockout configured
    var knockoutMatches: [KnockoutMatch]
}

enum BracketStatus: String, Codable, Sendable {
    case setup
    case groupStage
    case configuringKnockout
    case knockout
    case finished
}

struct BracketGroup: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String           // "A", "B", "C"
    var teams: [FixedTeam]
    var matches: [GroupMatch]
    var advanceCount: Int?     // set when host configures knockout
}

struct GroupMatch: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let teamAID: String
    let teamBID: String
    var scoreA: Int?
    var scoreB: Int?
    var winnerTeamID: String?
    var completedAt: Date?
}

struct KnockoutMatch: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let round: KnockoutRound
    let position: Int           // for bracket ordering
    var teamAID: String?        // nil = bye
    var teamBID: String?
    var sets: [SetScore]
    var winnerTeamID: String?
    var completedAt: Date?
}

enum KnockoutRound: String, Codable, Sendable {
    case quarterfinal
    case semifinal
    case final
    case thirdPlace
}

struct SetScore: Codable, Hashable, Sendable {
    var teamAScore: Int
    var teamBScore: Int
}
```

New files (4):
- `Domain/Models/BracketTournamentModels.swift`
- `Domain/Services/BracketTournamentService.swift` — protocol
- `Data/Stubs/StubBracketTournamentService.swift`
- `Data/Firebase/FirebaseBracketTournamentService.swift`

Service protocol methods:
- `createBracket(in:title:teams:groups:)`
- `fetchBrackets(for tournament:)`
- `recordGroupMatchResult(...)`
- `configureKnockout(bracketID:, advanceCounts:[groupID:Int], bestOf:Int)` — randomizes pairings + assigns byes
- `recordKnockoutSet(...)`
- `observeBracket(bracketID:)`

Edited files (3):
- `Domain/Services/AppEnvironment.swift` — register `bracketTournamentService`
- `Data/Firebase/FirestorePaths.swift` — `brackets`, `bracket` paths
- `App/AppEnvironment.swift` — wire service for both stub + Firebase environments

Done when:
- All bracket models compile
- Stub creates a bracket, records group results, configures knockout (random pairing tested), records set scores, advances rounds
- Firebase implementation writes/reads from `tournaments/{tID}/brackets/{bID}` correctly
- No UI yet — verified via stub + unit-test-style trial

---

### Milestone 22: Bracket Tournament — setup flow 📋 PLANNED

Goal:
- Host can create a bracket tournament from inside a Tournament's "Tournaments" tab. List view + create sheet.

Scope:
- `BracketListView` shown inside the Tournaments tab. Lists all bracket tournaments under the parent Tournament. `+` button to create.
- `CreateBracketSheet`: title → add teams (each: name + 2 players from tournament roster) → create groups → assign each team to a group → "Start Group Stage" button
- After creation, status flips to `.groupStage` and lands on the group stage view (built in M23)

New files (3):
- `Features/Tournament/Bracket/BracketListView.swift`
- `Features/Tournament/Bracket/CreateBracketSheet.swift`
- `Features/Tournament/Bracket/BracketRow.swift` (list item)

Edited files (1):
- `Features/Tournament/TournamentDetailView.swift` — replace Tournaments tab placeholder with `BracketListView`

Done when:
- Host opens Tournaments tab → sees list (or empty state)
- Tap `+` → fills in title, teams, groups, assignments → tap Start
- New bracket appears in the list with status "Group Stage"
- Tapping it opens placeholder for M23 view

---

### Milestone 23: Bracket Tournament — group round-robin phase 📋 PLANNED

Goal:
- Display group matches and live standings during the group-stage phase. Host enters scores per match; standings update live.

Scope:
- `GroupRoundRobinView` shown when bracket status is `.groupStage`
- Tabs / segments per group (Group A, Group B, …)
- Each group shows: round-robin matches (with score entry) + live standings table (Team / W / L / Pts)
- "Configure Knockout" button appears when ALL group matches across ALL groups are completed
- Tapping a match opens score entry sheet (single set, integer scores)

Standings logic (computed):
- W/L from completed matches
- Points = wins (1 per win, 0 per loss). Tie-breaker: head-to-head → point differential → random
- Sort: points desc → wins desc → diff desc → name

New files (3):
- `Features/Tournament/Bracket/GroupRoundRobinView.swift`
- `Features/Tournament/Bracket/GroupStandingsTable.swift`
- `Features/Tournament/Bracket/GroupMatchScoreSheet.swift`

Edited files (1):
- `Features/Tournament/Bracket/BracketDetailView.swift` (created in this milestone) — phase router (group → configure → knockout → finished)

Done when:
- Host opens an in-progress bracket → sees groups with their round-robin matches
- Tapping any match → score entry → save → standings update live
- "Configure Knockout" button appears once all matches done
- Cancelling out + reopening preserves state (Firebase persistence)

---

### Milestone 24: Bracket Tournament — configure knockout phase 📋 PLANNED

Goal:
- After group stage completes, host configures: how many teams advance per group + best-of-N for knockout. System then randomly pairs advancing teams (with bye handling for odd counts).

Scope:
- `ConfigureKnockoutSheet`: per-group stepper for advance count (1...teamCount-1) + best-of segmented control (1 / 3 / 5 / 7)
- On save: status flips to `.knockout`, system collects advancing teams, shuffles, pairs them, generates `KnockoutMatch` records with bye handling
- Random pairing algorithm: shuffle → pair sequentially → odd team gets bye to next round

New files (2):
- `Features/Tournament/Bracket/ConfigureKnockoutSheet.swift`
- `Domain/Services/KnockoutPairingEngine.swift` — pure pairing logic with bye assignment

Edited files (1):
- `BracketDetailView` — show "Configure Knockout" button + present sheet

Done when:
- Host inputs advance counts → tap Save → bracket transitions to knockout state
- Random pairing visible (refresh shows same pairing — persisted)
- Bye teams correctly skip first round
- Best-of-N value persisted

---

### Milestone 25: Bracket Tournament — visual knockout bracket 📋 PLANNED

Goal:
- The signature visual bracket UI from the screenshot. QF → SF → Final layout with team cards, set scores, seed badges, BYE display, connecting lines, dates, 3rd place match, trophy on Final.

Scope:
- `KnockoutBracketView` — horizontally scrollable visual bracket
- Each match rendered as `BracketMatchCard`: 2 rows (team name + small seed badge + bold score per set)
- BYE state: vertical "BYE" panel on right of card
- `BracketConnector` — SwiftUI `Path` drawing the lines between rounds
- Round labels: "QF · Game N", "SF · Game N", "🏆 Final", "3rd place"
- Tapping a match opens `KnockoutSetEntrySheet` — host enters set scores. Auto-detects match winner once enough sets are decided
- 3rd place match auto-generated from SF losers
- Champion display when Final completes

New files (4):
- `Features/Tournament/Bracket/KnockoutBracketView.swift`
- `Features/Tournament/Bracket/BracketMatchCard.swift`
- `Features/Tournament/Bracket/BracketConnector.swift`
- `Features/Tournament/Bracket/KnockoutSetEntrySheet.swift`

Edited files (1):
- `BracketDetailView` — route knockout phase to `KnockoutBracketView`; show champion when finished

Done when:
- Visual bracket matches the reference screenshot layout (QF→SF→Final, 3rd place, trophy icon, seed badges, set scores, BYE)
- Host can tap any match → enter set scores → match auto-completes when winner is decided
- Bracket auto-progresses: SF winners populate Final, SF losers populate 3rd place
- Final winner is shown as champion
- Killing app preserves all state

---

### Milestone 26: Recap suite — weekly squad recap + game day recap ✅ IMPLEMENTED

Status (2026-06-11): ✅ Implemented as specced — 85/85 unit tests green (17 new builder tests).
Files landed: `SquadRecap` / `GameDayRecap` models, `SquadRecapBuilder` / `GameDayRecapBuilder` /
`RecapImageRenderer` utilities, `Features/Recap/` (card views, sheets, view model, shared
`RecapCardStyle`), wiring in `FeedView` (toolbar), `GameViewModel.endDay` + `DayDetailView`
(auto-present day recap), `BracketKnockoutView` (champion transition).
Remaining: manual on-device QA (end a real day → recap presents once → share → no re-present).

Goal:
- Two shareable recap cards rendered from existing data through one shared image pipeline:
  1. **Weekly squad recap** — revives M15 as spec'd (plays, reactions, top play, top reactor over a rolling 7-day window).
  2. **Game day recap** (new) — when a day of play ends or a bracket crowns a champion: match count, top performer, biggest scoreline, champion 🏆.

Motivation:
- Every share is *outbound* visibility — the only feature class that reaches non-users while push (M6) stays blocked. Recap cards double as the "screenshotable B2B marketing material" the design strategy calls for.
- M15 was skipped when the only data was feed photos. Since then M10–M25 added matches, scores, standings, and champions — the game day recap is the stronger card now, and it reuses M15's render pipeline.

Scope decisions (locked):
- **Pure client-side derivation.** No new Firestore collections, no Cloud Functions (same as M15).
- **One shared pipeline**: `RecapImageRenderer` wraps `ImageRenderer` → PNG → `ShareLink`. Both cards use it.
- **Athletic Pro tokens.** Cards are built from `ThemeColor` / `ThemeTypography` / `SurfaceCard` / `ScoreText`. The champion variant is the one sanctioned use of Champion gold outside the M25 banner.
- **Game day recap auto-presents** — once, on the organizer's device, when `endDay` succeeds; and when `BracketDetailViewModel.champion` transitions nil → non-nil. No persistent entry point in v1 (decided 2026-06-11; quiet button on `GameSummaryView` is a follow-up).
- **Weekly recap entry**: toolbar button on `FeedView`, per the M15 spec. Window = last 7 days ending now, not calendar week.
- **One canonical layout per card.** No themes, no customization.

#### 26.1 Domain layer

- `Domain/Models/SquadRecap.swift` — per M15 §15.1, with one deviation found at build time:
  `topReactorName` → `topPosterName`. `Play.reactionSummary` is `[emoji: count]` and carries
  no reactor identity, so the spec's sanctioned fallback ("top play poster") is the v1 field.
- `Domain/Models/GameDayRecap.swift`:
```swift
struct GameDayRecap: Equatable {
    let gameTitle: String
    let date: Date
    let playerCount: Int
    let matchCount: Int
    let topPerformerName: String?     // most wins that day; tie → most played → name
    let biggestScoreline: String?     // e.g. "21–9", max |scoreA−scoreB| among scored matches
    let championTeamName: String?     // set for the bracket-final variant
}
```

#### 26.2 Shared utilities (pure, Tier 1 testable)

- `Shared/Utilities/SquadRecapBuilder.swift` — per M15 §15.2.
- `Shared/Utilities/GameDayRecapBuilder.swift` — `static func build(session: GameSession, matches: [GameMatch], champion: FixedTeam?) -> GameDayRecap`. Matches come from the existing `fetchMatches(for:)`.
- `Shared/Utilities/RecapImageRenderer.swift` — `@MainActor` helper rendering any recap view at 1080×1920 @3x; returns `UIImage?`.

#### 26.3 Feature layer

New folder `Features/Recap/`:
- `WeeklyRecapView.swift`, `WeeklyRecapSheet.swift`, `WeeklyRecapViewModel.swift` — per M15 §15.3.
- `GameDayRecapView.swift`, `GameDayRecapSheet.swift` — card + sheet with `ShareLink`; champion variant swaps accent → gold and adds the trophy treatment.

Edited files:
- `Features/Feed/FeedView.swift` — toolbar recap button (sheet presentation only).
- `Features/Tournament/GameViewModel.swift` — after `endDay` succeeds, build recap from the freshly fetched matches; expose `dayRecap: GameDayRecap?` to trigger the sheet. Skip when `matchCount == 0`.
- `Features/Tournament/BracketKnockoutView.swift` (or `BracketDetailViewModel`) — present the champion recap once when `champion` becomes non-nil; guard against re-presenting on every reopen (`@AppStorage` seen-flag keyed by bracket ID, or only fire on the transition observed live).

#### 26.4 Edge cases

- Empty week → M15 empty state; no share button.
- Day with zero completed matches → no auto-present.
- Matches without scores (winner-only) → omit `biggestScoreline`.
- Top performer tie → most played, then name (deterministic).
- `ImageRenderer` returns nil → "Couldn't generate recap" + retry.

#### 26.5 Build order

1. `SquadRecapBuilder` + `GameDayRecapBuilder` + unit tests (fixtures: empty week, tie cases, scoreless matches).
2. Card views iterated in Xcode previews with fixture data (both variants, both color schemes).
3. `RecapImageRenderer` + `ShareLink` round-trip; verify PNG quality in Messages.
4. Weekly wiring (FeedView toolbar).
5. Day recap wiring (`endDay` success path), then champion variant.
6. Manual QA: end a real day on device → recap appears once → share → reopen, no re-present.

#### 26.6 Done when

- Feed toolbar → weekly recap card summarizing the last 7 days; Share exports a high-res PNG.
- Ending a day with ≥1 completed match auto-presents the day recap exactly once.
- A bracket final completing presents the champion recap with gold treatment.
- Builders fully covered by Tier 1 tests.

#### 26.7 Out of scope / follow-ups

- Persistent recap button on `GameSummaryView`.
- Monthly / season recaps; year-in-review.
- Auto-prompt via push (blocked on M6).
- Animated (Stories-format) recap.

---

### Milestone 27: Play streaks 📋 PLANNED

Goal:
- Revive M16 exactly as spec'd: squad-level "🔥 N day streak" badge on the Feed, computed locally from the already-fetched feed. See M16 §16.1–16.8 for the full design — it remains accurate post-rename (Play/Feed naming unchanged).

Deltas from the original M16 spec (2026-06-11):
- Badge styling uses Athletic Pro tokens — flame on **Energy orange** (`ThemeColor`), `Badge` component from `Shared/Design/Components/`.
- Cross-feature with M26: when `currentStreak >= 2`, the weekly recap card shows the streak line. One extra field on the card view; `StreakCalculator` is the shared source.
- Test list per M16 §16.6 goes into `PlaySnappTests` (Swift Testing), alongside the existing engine suites.

Done when: per M16 §16.7. Out of scope: per M16 §16.8 (per-user streaks, freezes, push nudges, milestone badges).

---

### Milestone 28: Mascot 📋 PLANNED (design-led, phased)

Goal:
- Introduce a brand mascot for retention moments — empty states, onboarding, celebrations — without undermining the Athletic Pro / B2B-credible direction.

This resolves open question #4 in `docs/Design Ideas/design-ideas-EN.md` (answer: **yes**, phased).

Hard constraints (from the design guide):
- "Warmth without being childish" — Headspace / Strava-2023 illustration energy, not cartoon.
- Sport-agnostic (squads span volleyball → badminton → pickup soccer).
- Single line-weight illustration style so it folds into the existing Tier 4 plan — the mascot **becomes** the Tier 4.1 empty-state and Tier 4.2 onboarding illustrations rather than adding new asset scope.
- No regional cultural coding.

#### Phase 28a — Concept (design only, no code)

- 2–3 character directions (silhouette, personality, working name), each shown in one empty-state mock and one celebration mock.
- Founder picks one. Deliverable: concept sheet (Figma or PNG).

#### Phase 28b — Static poses + empty-state integration

- 6 poses: empty feed · no squad · no friends · no bracket · no notifications · generic error. Formats per the design guide (SVG preferred + PNG @2x @3x), into an asset catalog.
- Code: new `Shared/Design/Components/EmptyStateView.swift` — image + headline + body + optional CTA, themable. Replace the `ContentUnavailableView` usages in `FeedView`, `GameView`, `GameDetailView`, `GameBillboardView`, `GameHistoryView`, `BracketListView`, `PlayerPickerSheet`, `NotificationsView`, `FriendsView` (audit found 11 call sites).
- 3 onboarding hero panels for the first-launch flow (`WidgetIntroView` + onboarding screens).

#### Phase 28c — Moments

- Champion celebration: mascot + trophy illustration upgrading `ChampionBanner` (Tier 2.5), plus SwiftUI confetti (designer supplies colors only).
- Streak nudge: small mascot variant beside the M27 badge when a streak is at risk.

#### Phase 28d — Animation (deferred)

- Lottie vs SwiftUI keyframes decided when 28c ships. Not before.

Done when (per phase): 28a — direction picked. 28b — every empty state in the app shows the mascot via `EmptyStateView`; no `ContentUnavailableView` left on user-facing surfaces. 28c — bracket finale shows the celebration illustration.

Out of scope: mascot in the widget (payload size), animated stickers, mascot-voiced copy system.

---

### Milestone 29: Career stats on Profile 📋 PLANNED

Goal:
- Surface per-squad career stats — games played, wins, losses, win rate — on the Profile tab.

Motivation (from 2026-06-11 code audit):
- `FirebaseGameService.recordResult` has been writing `squads/{squadID}/leaderboard/{userID}` (`totalPlayed` / `totalWins` / `totalLosses`) since M10 — but **no domain model and no read API exist**. The data is already accumulating; this milestone is mostly read-and-render.

Scope decisions (locked):
- **v1 is read-only** from the leaderboard collection. No new writes, no schema change.
- **Per-squad, not cross-squad.** Stats shown for the active squad, with a per-squad breakdown for all memberships.
- **Partner chemistry deferred.** `partnerships` is per-session; aggregating needs cross-session match scans or forward-only denormalization into leaderboard docs. Defer until demanded.

#### 29.1 Domain layer

- `LeaderboardEntry` model (in `GameModels.swift`): `userID`, `totalPlayed`, `totalWins`, `totalLosses`, computed `winRate`.
- `GameServicing.fetchLeaderboard(squadID: String) async throws -> [LeaderboardEntry]`.

#### 29.2 Data layer

- `FirebaseGameService` — one-shot collection read of `leaderboard`; reuse the existing serializer fields from the write path.
- `StubGameService` — canned entries for previews.

#### 29.3 Feature layer

- `Features/Profile/ProfileStatsSection.swift` — "Stats" card: Played / W / L / win-rate for the active squad (using `ScoreText` + `SurfaceCard`), expandable per-squad rows for other memberships.
- `ProfileViewModel` — load stats concurrently with the existing profile + squads fetch.

Stretch (gate on time): recent form — last 10 matches as W/L dots, from the newest sessions' `matches` subcollections.

#### 29.4 Build order

1. Model + protocol + stub + previews.
2. Firebase read + verify numbers match the billboard "All time" expectations on a real squad.
3. Profile UI section.

#### 29.5 Done when

- Profile shows real career numbers for the signed-in user in the active squad.
- Per-squad breakdown lists every membership; squads with no games show a friendly zero state.
- Stub-backed previews render without Firebase.

#### 29.6 Out of scope / follow-ups

- Cross-squad aggregate totals; charts/graphs.
- Partner chemistry; head-to-head records.
- Achievements/badges (future milestone — natural mascot tie-in).

---

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

---

## 11. Changelog — Tournament→Game rename + game-level player management (2026-06-10)

> The 132 "tournament" references above are historical and left as written. As of this change,
> the top-level entity is a **Game**; "Tournament" now refers only to the bracket sub-tab.

**Rename (code + UI + Firestore):**
- `Tournament`→`Game`, `TournamentSession`→`GameSession`, `TournamentPlayer`→`GamePlayer`, `TournamentMatch`→`GameMatch`, `TournamentStatus`→`GameStatus`.
- Services: `TournamentService(Servicing)`→`GameService(Servicing)`, `Firebase/StubTournamentService`→`Firebase/StubGameService`, `TournamentRotationEngine`→`GameRotationEngine`.
- Views: `TournamentView`→`GameView`, `TournamentDetailView`→`GameDetailView`, `TournamentViewModel`→`GameViewModel`, plus `RoundView`/`BillboardView`/`SummaryView`/`HistoryView`.
- Firestore: collection `tournaments`→`games`, field `tournamentID`→`gameID`, path helpers `FirestorePaths.game(s)`/`gameSession(s)`.
- **Preserved** (bracket sub-feature): `BracketTournament*` types, `parentTournamentID`, the bracket service's `tournamentID` params, the "Tournaments" tab label, and `Features/Tournament/` folder name.

**Player management:**
- ⋯ menu reduced to **Add Players** + **End Game**; day creation (Walk-up / Schedule) moved to buttons on the Days tab.
- Add Players persists to `game.players` via the existing Squad/Friends/Guest picker; in-session adding removed from the walk-up + scheduled-day sheets.
- `removePlayer(playerID:from:)` added (protocol + Firebase + Stub); organizer removes a player from the Board tab. Mid-session days keep their own player copy.

**Knockout UI:** redesigned as a horizontal single-elimination tree (connector lines, seeded nodes, "Winner of <round>" placeholders for ungenerated matches).

Committed on branch `feature/game-rename-player-mgmt`. Build green; full test suite passes.
