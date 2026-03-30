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

- `Sign in with Apple`
- `Push Notifications`
- `Background Modes`

Add these background modes:

- `Remote notifications`
- `Background fetch` if you want best-effort widget refresh support

Add this capability to both app and widget targets:

- `App Groups`

Use the same group ID in both targets:

- `group.com.playsnap.shared`

## 5. Add Firebase

Add Swift Package dependencies for:

- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseStorage`
- `FirebaseMessaging`
- `FirebaseCore`

Then:

1. Create a Firebase project.
2. Register the iOS app bundle ID.
3. Download `GoogleService-Info.plist`.
4. Add it to the app target.

## 6. Wire startup

After Firebase packages are installed:

1. Verify [FirebaseConfiguration.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/FirebaseConfiguration.swift) can import `FirebaseCore`.
2. Keep `FirebaseConfiguration.configure()` as the single app bootstrap point.
3. Let [PlaySnapApp.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/App/PlaySnapApp.swift) call the environment bootstrap only.

## 7. First milestone target

Once the project opens successfully, the first implementation target should be:

1. Verify [FirebaseAuthService.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/FirebaseAuthService.swift) can complete real Apple sign-in and restore a Firebase-backed session
2. Replace [StubStorageService.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Stubs/StubStorageService.swift) with [FirebaseStorageService.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/FirebaseStorageService.swift)
3. Persist the current user profile and session flags to Firestore
4. Complete the profile flow

## 8. Current scaffold

The repo already includes:

- App router and app shell
- Auth, onboarding, feed, notifications, and profile screens
- `Domain` contracts and models
- `Data` implementations for stubs, local widget sync, and Firebase-backed auth bootstrap
- `PreviewSupport` fixtures separated from production models
- Widget storage and widget placeholder files
- Firebase path helpers and camera permission placeholder

The next coding step after opening in Xcode is to wire Milestone 1 against the `Domain -> Data` boundaries, not to redesign the structure again.

## 9. Immediate next actions

Based on the current repo state, do these next in order:

1. Add capabilities in Xcode for the app target and widget target.
2. Create the shared `App Groups` ID: `group.com.playsnap.shared`.
3. Add the Firebase packages.
4. Add `GoogleService-Info.plist` to the app target.
5. Confirm [PlaySnapApp.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/App/PlaySnapApp.swift) is running in `.firebasePrepared`.
6. In Firebase Console, enable the Apple auth provider and create the Firestore database.
7. Verify sign-in works, then implement [FirebaseStorageService.swift](/Users/andythang/personal-project/PlaySnapp/PlaySnapp/Data/Firebase/FirebaseStorageService.swift).

Right now, the remaining setup gaps are external configuration:

- no `.entitlements` files are committed yet for App Groups
- Apple auth still depends on Firebase Console provider setup
- Firestore must exist in the Firebase project before the profile/session flow can persist data
