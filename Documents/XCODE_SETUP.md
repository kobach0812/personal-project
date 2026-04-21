# Xcode Setup

This repo now contains a generated Xcode project at [PlaySnapp.xcodeproj](/Users/andythang/personal-project/PlaySnapp/PlaySnapp.xcodeproj).

## 1. Open the existing app project

1. Open Xcode.
2. Open [PlaySnapp.xcodeproj](/Users/andythang/personal-project/PlaySnapp/PlaySnapp.xcodeproj).

## 2. Add the existing source folders

The app source already lives in:

- `/Users/andythang/personal-project/PlaySnapp/PlaySnapp`
- `/Users/andythang/personal-project/PlaySnapp/WidgetExtension`

The project is using filesystem-synchronized groups, so new folders added under the app root are picked up automatically.

## 3. Check the widget target

This project already contains a widget target: `WidgetExtensionExtension`.

You do not need to create another widget target unless you intentionally want to rename or rebuild it.

Verify this instead:

1. The widget target still points at the files inside `/Users/andythang/personal-project/PlaySnapp/WidgetExtension`.
2. `/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Shared/Widget/AppGroupStore.swift` is included in both the app target and the widget target.
3. `PlaySnapWidget.swift` is the only widget entry file in the widget target.

## 4. Add capabilities

Add these capabilities to the app target:

- `Sign in with Apple` (add now even though Apple sign-in is parked — the entitlement must be present before enabling it)
- `Background Modes` → check `Remote notifications`

Add this capability to both app and widget targets:

- `App Groups`

Use the same group ID in both targets:

- `group.com.playsnap.shared`

> **Push Notifications**: This capability requires a paid Apple Developer account ($99/year).
> Skip it for now. Phone auth and device token registration will not work until it is added.
> Add it when you upgrade to a paid account before TestFlight.

## 5. Add Firebase

Firebase packages are already added via Xcode's SPM integration:

- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseStorage`
- `FirebaseMessaging`
- `FirebaseCore`

`GoogleService-Info.plist` is already in the app target. Verify its bundle ID matches `com.andythang.PlaySnapp`.

## 6. Wire startup

[FirebaseConfiguration.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/FirebaseConfiguration.swift) handles `FirebaseApp.configure()` with a guard against double-init.

[PlaySnapApp.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/App/PlaySnapApp.swift) is running `.firebasePrepared` — Firebase auth and Firestore are live.

No changes needed here.

## 7. Current auth approach

Apple Sign In is temporarily parked because it requires a paid Apple Developer account for the entitlement to activate on device.

The current auth screen offers:

- Email / password (sign in or register)
- Phone number with SMS verification code

**Email auth is ready and works end to end.** Use this to test the onboarding flow.

**Phone auth** requires the Firebase Phone provider to be enabled in the Firebase Console and a real device (APNS token). Skip it for now.

When a paid developer account is available:

1. Enable the `Push Notifications` capability in Xcode
2. Enable the `Sign in with Apple` capability in Xcode
3. Enable the Apple provider in the Firebase Console (Authentication → Sign-in methods)
4. Uncomment [AppleSignInProvider.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/AppleSignInProvider.swift) and wire it into `FirebaseAuthService`

## 8. Current scaffold

The repo already includes:

- App router and app shell
- Auth, onboarding, feed, notifications, and profile screens
- `Domain` contracts and models
- `Data` implementations: Firebase-backed auth, Firestore session/profile, local widget sync, and stubs for squad/play/notifications
- `PreviewSupport` fixtures separated from production models
- Widget storage and widget placeholder files
- `FirestorePaths` and `StoragePaths` path helpers
- `LocalOnboardingFlagStore` for offline-resilient onboarding flags
- Camera permission placeholder and shared utilities

## 9. Immediate next actions

Steps 1–6 below are the ordered path to Milestone 1 completion:

1. ✅ Firebase packages added
2. ✅ `GoogleService-Info.plist` added to app target
3. ✅ `PlaySnapApp.swift` running in `.firebasePrepared`
4. **You** → In Firebase Console, enable Email/Password auth provider if not done
5. **You** → In Firebase Console, create the Firestore database, set rules to allow authenticated reads/writes
6. **You** → Configure App Groups capability in Xcode (`group.com.playsnap.shared`) for both app and widget targets
7. Test email sign-in end to end: sign up → profile setup → squad setup → main tab
8. Verify `users/{uid}` document is created in Firestore after sign-in
9. Implement [FirebaseSquadService.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/) — create/join squad in Firestore (Milestone 2)

## 10. Remaining setup gaps

| Gap | Blocker |
|-----|---------|
| App Groups capability not configured in Xcode | Widget data sharing won't work until this is done |
| Push Notifications capability missing | Requires paid Apple Developer account |
| Phone auth not testable | Requires real device + APNS token |
| Apple Sign In parked | Requires paid Apple Developer account + Push Notifications capability |
| `FirebaseSquadService` not implemented | Squad data is stub-only (in-memory, not persisted to Firestore) |
| `FirebasePlayService` not implemented | Feed data is stub-only |
| `FirebaseStorageService.uploadPhoto/Video/Avatar` not implemented | Upload pipeline is Milestone 3 |
