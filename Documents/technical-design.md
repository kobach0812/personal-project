# PlaySnap MVP Technical Design

## 1. Purpose

This document turns the MVP product spec into an implementation plan for the iPhone app, widget, and backend services.

The main goal is to support one reliable loop:

Capture -> upload -> squad sees it -> squad reacts -> poster is notified.

## 2. Architecture summary

PlaySnap should ship as:

- One iOS app target built with `SwiftUI`
- One widget extension built with `WidgetKit`
- Firebase as the backend
- Optional Cloud Functions for fan-out, invite resolution, and notification triggers

Core technologies:

- `SwiftUI` for UI
- `AVFoundation` for camera capture
- `Firebase Auth` for sign-in
- `Cloud Firestore` for app data
- `Firebase Storage` for media
- `Firebase Cloud Messaging` for push
- `App Groups` for local app-to-widget shared data

### Maintainability rules

From this point forward, the codebase should follow these non-negotiable rules:

- `Domain` owns models and protocol contracts
- `Data` owns concrete implementations for Firebase, local persistence, and stubbed development data
- `PreviewSupport` owns sample fixtures and preview-only data
- `Features` own screens and view models only
- Views never talk directly to Firebase, camera, storage, or widget APIs
- Only UI-facing types should be `@MainActor`
- Project-wide default actor isolation must stay off
- New integrations should be added behind protocol boundaries first, then wired into the environment container
- Shared cross-target code must stay small and explicit

## 3. Important design corrections

Your proposed direction is good, but these changes matter:

1. `Reaction` should not be stored as a mutable array inside `Play`
- Multiple users reacting at the same time will cause write contention and merge problems
- Store reactions as a subcollection or aggregate summary instead

2. `User.fcmToken` should not be a single string
- A user can have multiple devices or token rotations
- Store device tokens in a per-device subcollection

3. "Zero phone storage" cannot be literal for video capture
- Photo data can stay mostly in memory
- Video capture will still use a temporary local file during recording and upload
- The real promise should be: no permanent media storage after successful upload

4. `WidgetCenter.shared.reloadAllTimelines()` only updates the local device
- It does not instantly refresh squadmates' widgets on other phones
- Widget freshness across users must be treated as best effort, not guaranteed real time

## 4. Project structure

Current actual structure (as of Milestone 1):

```text
PlaySnap/
├── App/
│   ├── PlaySnapApp.swift
│   ├── AppRouter.swift
│   └── AppEnvironment.swift
├── Domain/
│   ├── Models/
│   │   ├── AppSession.swift
│   │   ├── AppUser.swift
│   │   ├── Squad.swift
│   │   ├── Play.swift
│   │   ├── PlayReaction.swift
│   │   ├── DeviceRegistration.swift
│   │   └── AppNotification.swift
│   └── Services/
│       ├── AuthService.swift
│       ├── OnboardingProgressService.swift
│       ├── UserProfileService.swift
│       ├── PlayService.swift
│       ├── SquadService.swift
│       ├── StorageService.swift
│       ├── NotificationService.swift
│       └── WidgetSyncService.swift
├── Data/
│   ├── Firebase/
│   │   ├── FirebaseConfiguration.swift
│   │   ├── FirestorePaths.swift          ← Firestore collection/document paths
│   │   ├── StoragePaths.swift            ← Firebase Storage upload/download paths
│   │   ├── FirebaseIntegrationError.swift
│   │   ├── FirebaseAuthGateway.swift     ← thin wrapper over Firebase Auth SDK
│   │   ├── FirebaseSessionDocumentStore.swift
│   │   ├── FirebaseAuthService.swift
│   │   ├── FirebaseOnboardingProgressService.swift
│   │   ├── FirebaseUserProfileService.swift
│   │   ├── FirebaseStorageService.swift  ← upload stubs, wired in Milestone 3
│   │   ├── AppleSignInProvider.swift     ← parked until paid dev account
│   │   ├── FirebaseSquadService.swift    ← TODO: Milestone 2
│   │   ├── FirebasePlayService.swift     ← TODO: Milestone 4
│   │   └── FirebaseNotificationService.swift ← TODO: Milestone 6
│   ├── Local/
│   │   ├── LocalWidgetSyncService.swift
│   │   └── LocalOnboardingFlagStore.swift  ← offline-resilient onboarding flags
│   └── Stubs/
│       ├── StubSessionStore.swift        ← shared in-memory state for dev mode
│       ├── StubAuthService.swift
│       ├── StubOnboardingProgressService.swift
│       ├── StubUserProfileService.swift
│       ├── StubSquadService.swift
│       ├── StubPlayService.swift
│       ├── StubStorageService.swift
│       └── StubNotificationService.swift
├── Features/
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   └── AuthViewModel.swift
│   ├── Onboarding/
│   │   ├── ProfileSetupView.swift
│   │   ├── ProfileSetupViewModel.swift
│   │   ├── SquadSetupView.swift
│   │   ├── SquadSetupViewModel.swift
│   │   ├── WidgetIntroView.swift
│   │   └── WidgetIntroViewModel.swift
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   ├── CameraViewModel.swift
│   │   └── CapturePreviewView.swift
│   ├── Feed/
│   │   ├── FeedView.swift
│   │   ├── FeedViewModel.swift
│   │   ├── PlayCardView.swift
│   │   └── PlayDetailView.swift
│   ├── Notifications/
│   │   ├── NotificationsView.swift
│   │   └── NotificationsViewModel.swift
│   └── Profile/
│       ├── ProfileView.swift
│       └── ProfileViewModel.swift
├── Infrastructure/
│   └── Camera/
│       └── CameraManager.swift
├── PreviewSupport/
│   └── Fixtures/
│       └── AppFixtures.swift
├── Shared/
│   ├── Utilities/
│   │   ├── ImageCompressor.swift
│   │   ├── VideoThumbnailGenerator.swift
│   │   └── TemporaryFileCleaner.swift
│   └── Widget/
│       └── AppGroupStore.swift
└── WidgetExtension/
    ├── PlaySnapWidget.swift
    ├── WidgetProvider.swift
    ├── WidgetEntry.swift
    └── WidgetEntryView.swift
```

Notes:

- `Domain` must not import Firebase or WidgetKit
- `Data` may import Firebase, WidgetKit, or storage SDKs
- `PreviewSupport` must not leak into production persistence code
- `Utilities/` should stay small or it becomes a junk drawer
- Files marked `← TODO` are the next Firebase implementations to write

## 5. Runtime architecture

The app should be separated into these responsibilities:

- UI layer
  - SwiftUI views and navigation
- View model layer
  - screen state and async orchestration
- Domain layer
  - business entities and service contracts
- Data layer
  - Firebase, local widget sync, and stub implementations
- Infrastructure layer
  - low-level camera wrappers and platform adapters

Preferred rule:

- Views do not talk directly to Firebase
- Views call view models
- View models call domain service contracts
- Data implementations own side effects

## 6. Data model

### AppUser

Required fields:

- `id`
- `name`
- `primarySport`
- `avatarURL`
- `squadIDs` — array of squads the user belongs to (see M12)
- `activeSquadID` — currently selected squad; drives feed/camera/game/widget (see M12)
- `createdAt`
- `updatedAt`

Deprecated (retained read-only for one release during M12 migration):
- `squadId` — legacy single-squad field

### Squad

Required fields:

- `id`
- `name`
- `sport`
- `createdBy` — user ID of the creator; used for permission checks
- `inviteCode`
- `memberCount` — denormalized count; the authoritative list lives in the `members` subcollection
- `createdAt`

Note: the Swift `Squad` model currently stores `memberIDs: [String]` for in-memory stub use. When `FirebaseSquadService` is implemented, member IDs will come from the Firestore `members` subcollection, and `memberCount` will be a field on the squad document.

### Play

Required fields:

- `id`
- `squadID`
- `senderID`
- `mediaType` (`photo` or `video`)
- `mediaURL` — download URL for client display
- `storagePath` — Firebase Storage path; required for server-side cleanup and migrations
- `thumbnailURL`
- `caption`
- `durationSeconds`
- `createdAt`

Optional denormalized fields:

- `senderName`
- `senderAvatarURL`
- `reactionSummary` — lightweight emoji → count map; reactions subcollection is authoritative

### PlayReaction

Required fields:

- `userId`
- `emoji`
- `createdAt`

### DeviceRegistration

Required fields:

- `deviceId`
- `fcmToken`
- `platform`
- `appVersion`
- `updatedAt`

### AppNotification

Required fields:

- `id`
- `type`
- `title` — localised display string
- `message` — localised display string
- `actorID` — user who triggered the notification (poster or reactor)
- `recipientID` — user who should receive it; used by Cloud Functions for fan-out
- `playID`
- `squadID`
- `createdAt`
- `readAt`

## 7. Firestore layout

Recommended schema:

```text
users/{userId}
users/{userId}/devices/{deviceId}
users/{userId}/notifications/{notificationId}
users/{userId}/memberships/{squadId}                        # M12
users/{userId}/friends/{friendUserId}                       # M11

squads/{squadId}
squads/{squadId}/members/{userId}
squads/{squadId}/plays/{playId}
squads/{squadId}/plays/{playId}/reactions/{userId}
squads/{squadId}/tournaments/{sessionId}                    # M10 / M13
squads/{squadId}/tournaments/{sessionId}/matches/{matchId}  # M13
squads/{squadId}/leaderboard/{userId}                       # M10

friendRequests/{requestId}                                  # M11; id = "fromUid_toUid"
invites/{inviteCode}
```

See implementation-plan.md for field-level details on the M11/M12/M13 collections.

Why this shape:

- User-specific data stays under the user
- Squad data stays scoped to the squad
- Reactions are isolated per user, which avoids array merge conflicts
- Invite codes can be resolved directly without scanning squads

## 8. Storage layout

Firebase Storage paths are centralised in `Data/Firebase/StoragePaths.swift`.
Never build storage paths inline in upload code.

```text
squads/{squadId}/plays/{playId}/original.jpg
squads/{squadId}/plays/{playId}/original.mov
squads/{squadId}/plays/{playId}/thumbnail.jpg
avatars/{userId}/avatar.jpg
```

Always store both:

- download URL on the Firestore document (`mediaURL`, `thumbnailURL`, `avatarURL`) for client display
- storage path on the Firestore document (`storagePath`) for server-side cleanup and migrations

## 9. Auth flow

Intended production flow (requires paid Apple Developer account):

1. User signs in with Apple
2. App exchanges Apple credential with Firebase Auth
3. App checks for `users/{uid}`
4. If missing, create user shell document
5. If profile incomplete, route to profile setup
6. If no squad membership, route to squad setup
7. Otherwise route to camera

Current MVP workaround (email / phone):

- Apple Sign In is parked in `AppleSignInProvider.swift` until a paid developer account is available
- The auth screen offers email/password and phone number (SMS) sign-in instead
- The routing logic (steps 3–7) is identical regardless of sign-in method

Important rule:

- Auth and profile completion are separate states

## 10. Squad and invite flow

### Create squad

1. User enters squad name
2. App creates `squads/{squadId}`
3. App creates `squads/{squadId}/members/{uid}`
4. App appends to `users/{uid}.squadIDs` and sets `activeSquadID` if first squad
5. App creates `users/{uid}/memberships/{squadId}`
6. App creates `invites/{inviteCode}`

### Join squad

1. User opens invite link or enters invite code
2. App resolves `invites/{inviteCode}`
3. App verifies invite is active
4. App writes membership document
5. App appends squad to `users/{uid}.squadIDs`; sets `activeSquadID` if first squad
6. App creates `users/{uid}/memberships/{squadId}`
7. App increments squad member count transactionally

For MVP:

- Users may belong to multiple squads; exactly one is active at a time
- One active invite code per squad is enough

## 11. Photo upload flow

Recommended sequence:

1. Capture photo
2. Compress image
3. Create `playId`
4. Upload original image to Storage
5. Upload thumbnail if needed
6. Write Firestore `Play` document
7. Write latest widget payload into App Group store on the local device
8. Reload local widget timelines
9. Trigger push fan-out

Notes:

- Firestore should not be written before the media upload succeeds
- The app should show local progress state during upload

## 12. Video upload flow

This is different from photo.

Recommended sequence:

1. Record video to a temporary file URL
2. Generate thumbnail from the temporary file
3. Create `playId`
4. Upload video with `putFileAsync`
5. Upload thumbnail
6. Write Firestore `Play` document
7. Delete the temporary local file
8. Update local widget cache
9. Trigger push fan-out

Critical note:

- Video cannot be implemented as "memory only"
- Temporary local file cleanup is required after successful upload or cancellation

## 13. Feed and reaction flow

### Feed

Feed listener should subscribe to:

- `squads/{activeSquadID}/plays`
- ordered by `createdAt desc`
- paginated if needed later
- re-bound when the user switches active squad (M12)

### Reactions

Recommended write model:

- one reaction document per user per play
- document ID should be the reacting `userId`

Benefits:

- one user can update their own reaction cleanly
- no duplicated reactions from the same user
- concurrent writes are safe

Optional optimization:

- maintain a lightweight `reactionSummary` map on `Play`
- update that summary in a Cloud Function if needed

## 14. Widget design

The widget should show:

- latest squad play thumbnail
- sender name
- relative timestamp

### Recommended widget data flow

1. Main app fetches latest relevant play
2. Main app writes a compact widget payload into the App Group container
3. Widget reads from the App Group store
4. App calls `WidgetCenter.shared.reloadTimelines(ofKind:)`

The payload should contain:

- `playId`
- `thumbnailURL`
- `senderName`
- `createdAt`
- `sport`

### Important constraint

Widgets are not guaranteed to refresh instantly across every squadmate device.

What is realistic for MVP:

- local widget updates reliably when that user interacts with the app
- other users receive push notifications immediately
- their widgets update on next allowed refresh, foreground launch, or successful background update

If the product promise requires true sub-second shared widget updates across devices, standard home screen widgets are the wrong primitive.

## 15. Notification design

Use FCM with two notification paths:

### New play

Trigger:

- new `Play` document created

Handler:

- Cloud Function reads squad members
- exclude sender
- load device tokens from `users/{uid}/devices`
- send push payload with `type=new_play`, `squadId`, `playId`

### New reaction

Trigger:

- new reaction document created

Handler:

- Cloud Function finds original poster
- send `type=new_reaction`, `playId`, `actorId`

For in-app notifications:

- optionally write `users/{uid}/notifications/{notificationId}`
- use this only if you want a notifications screen in MVP

## 16. App Group store design

Do not store only a raw URL string.

Store a small encoded payload instead:

```text
WidgetPayload
- playId
- squadId
- thumbnailURL
- senderName
- createdAt
- sport
```

Why:

- widget UI needs more than the image URL
- one object write is easier to version
- future fields can be added without breaking layout assumptions

## 17. Security rules

Minimum Firestore rules should enforce:

- users can read and update their own user document
- users can read only squads they belong to
- users can create plays only in their own squad
- users can create or update only their own reaction document
- users can write only their own device registration
- invite resolution is read-only and validated

Minimum Storage rules should enforce:

- users can upload media only into their own squad path
- users can upload avatar only into their own avatar path
- users can read media only if they belong to that squad

## 18. Build order

Recommended order for a real MVP:

1. Firebase setup, app target, widget target, App Groups
2. Sign in with Apple and user profile
3. Squad creation and join flow
4. Photo capture and upload
5. Feed listener and play detail screen
6. Reactions
7. Push notifications
8. Widget cache and widget UI
9. Video capture and upload
10. Fair-play rotation tournament / Game tab (M10)
11. Friends graph (M11)
12. Multi-squad membership (M12)
13. Multi-session Game + roster picker + Firestore match history (M13)
14. TestFlight, analytics, polish

Why this order:

- squad membership is foundational
- photo is simpler than video
- widget work should happen after the core feed data is stable

## 19. Decisions for MVP

These are the strongest decisions to lock now:

- Ship with `Sign in with Apple` as the primary auth method once a paid developer account is active; email/phone is the current working substitute
- Support multiple squads per user with a single "active" squad driving feed / camera / widget (M12)
- Start with photo first if video slows camera delivery
- Use reactions only, no comments
- Treat widget freshness as a differentiator, but not as the only notification path

## 20. Recommended next document

The next useful artifact is a short `implementation-plan.md` that breaks this design into milestones, tasks, and first tickets for the Xcode project.
