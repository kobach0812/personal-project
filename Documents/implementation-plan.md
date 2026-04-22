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

Status (as of 2026-04-22):
- Domain models, rotation engine, stub + Firebase services, setup/round/billboard views all shipped in-session.
- `Game` tab wired into `MainTab` / `PlaySnapApp`. Trophy button removed from `FeedView`.
- History/score-entry features are **not yet implemented** — see "Next up" below.

### Next up: score entry + match history (in-session only, Firebase later)

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

## 5. Current tickets (as of 2026-04-22)

Milestones 0–7 done. Milestone 8 (video) deferred. Milestone 10 (Game) core shipped. Sport field removed — app is badminton-only. Tab order: Feed · Game · Camera · Alerts · Profile. Immediate next tickets:

1. **Milestone 9: Polish** — sign-out flow, profile edit, loading/error state improvements, TestFlight prep
2. **Milestone 11: Friends** — social graph; unlocks roster-picker in M13
3. **Milestone 12: Multi-squad membership** — decouple `users/{uid}.squadID` into a memberships collection + active-squad switcher
4. **Milestone 13: Multi-session Game + roster picker** — promote match history to Firestore, many sessions per squad, participants get a live read-only view

Suggested ordering: 9 → 11 → 12 → 13. M13 depends on M11 (roster picker needs friends) and M12 is independent but natural to do before M13 so session-list queries are already per-squad.

---

### Milestone 11: Friends & social graph

Goal:
- Users can search for other PlaySnapp users by name and send a friend request. Once accepted, friends appear in each other's friend list and become candidates for squad invites and Game-session rosters (see Milestone 13).

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

### Milestone 12: Multi-squad membership

Goal:
- A user can belong to multiple squads simultaneously (e.g., "Tuesday Pickleball", "Work Badminton"), switch between them fluidly, and each squad retains its own plays, leaderboard, and Game sessions. Squad membership decoupled from the user document.

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

### Milestone 13: Multi-session Game + roster-based player selection

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
