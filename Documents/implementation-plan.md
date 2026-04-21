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

### Milestone 3: Photo capture and upload 🔄 IN PROGRESS

Goal:
- Make the camera usable and upload a photo end to end

Tasks:
- Build camera screen with AVFoundation live preview
- Implement camera permissions flow
- Capture photo
- Compress image
- Upload to Firebase Storage (`squads/{squadID}/plays/{playID}/original.jpg`)
- Create `Play` document in Firestore
- Return success state to UI
- Handle upload failure and retry UI

Done when:
- User can open camera immediately after onboarding
- User can capture and send a photo
- Photo appears in Storage and Firestore

### Milestone 4: Feed and play detail

Goal:
- Let squad members see uploaded plays

Tasks:
- Build feed screen
- Subscribe to squad plays in reverse chronological order
- Build play card UI
- Build full-screen play detail view
- Display image thumbnail and metadata
- Add empty state for new squad
- Add loading and error states

Done when:
- Squadmates see each other's plays in the feed
- Tapping a play opens the detail screen

### Milestone 5: Reactions

Goal:
- Add the simplest interaction loop

Tasks:
- Create reaction write model in Firestore
- Build emoji reaction UI
- Prevent duplicate reactions per user
- Show current user's reaction state
- Show reaction summary counts
- Handle optimistic updates or loading states

Done when:
- A user can react to a play
- The reaction is visible to other squad members

### Milestone 6: Push notifications

Goal:
- Notify users when the loop advances

Tasks:
- Register device token with FCM
- Store device registration under the user
- Create Cloud Function for `new_play`
- Create Cloud Function for `new_reaction`
- Send push to squadmates except sender
- Send reaction push to original poster
- Handle push deep-link routing in app

Done when:
- New play sends push to squadmates
- New reaction sends push to original poster

### Milestone 7: Widget integration

Goal:
- Make the latest squad play visible on the home screen

Tasks:
- Define widget payload model
- Build App Group storage helper
- Write latest play payload from app to shared store
- Build widget timeline provider
- Build widget entry view
- Reload widget timelines after local app updates
- Add widget setup education screen
- Test stale-data and empty-state behavior

Done when:
- Local widget renders the latest known squad play
- Widget handles empty and stale content safely

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

## 5. Current tickets (as of Milestone 2 completion)

Milestones 0, 1, and 2 are done. The immediate next tickets are:

1. **Build `CameraView` with AVFoundation live preview** — replace stub with real `AVCaptureSession` preview, request camera permission
2. **Capture and compress photo** — tap-to-capture, compress to JPEG before upload
3. **Implement `FirebaseStorageService.uploadPhoto`** — upload to `squads/{squadID}/plays/{playID}/original.jpg`
4. **Write `Play` document to Firestore** — create `squads/{squadID}/plays/{playID}` after upload completes
5. **Return success to UI and show in feed** — navigate back or show confirmation after post
6. **Configure App Groups in Xcode** — add capability to both app and widget targets, ID: `group.com.playsnap.shared` (needed for Milestone 7)
7. **Implement `FirebasePlayService`** — Firestore listener for squad feed (Milestone 4)

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
