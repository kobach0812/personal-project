# Xcode Setup

This repo now contains the app source scaffold, but it does not yet contain a generated `.xcodeproj`.

## 1. Create the app project

1. Open Xcode.
2. Create a new `iOS App` project named `PlaySnap`.
3. Use `SwiftUI` for the interface.
4. Use `Swift` as the language.
5. Save the project in `/Users/andythang/personal-project`.

## 2. Add the existing source folders

After the project is created:

1. Delete the default generated view files if you do not need them.
2. Add the `/Users/andythang/personal-project/PlaySnap` folder to the app target.
3. Add the `/Users/andythang/personal-project/WidgetExtension` folder to the widget target.

Use:

- "Create groups" if you want a cleaner navigator
- or "Create folder references" only if you prefer filesystem mirroring

For most teams, `Create groups` is the better choice.

## 3. Add the widget target

1. In Xcode, add a new `Widget Extension` target named `PlaySnapWidgetExtension`.
2. Point that target at the files inside `/Users/andythang/personal-project/WidgetExtension`.
3. Include `/Users/andythang/personal-project/PlaySnap/Shared/Widget/AppGroupStore.swift` in both the app target and the widget target.

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

1. Import `FirebaseCore` in [FirebaseConfiguration.swift](/Users/andythang/personal-project/PlaySnap/Infrastructure/Firebase/FirebaseConfiguration.swift).
2. Call `FirebaseApp.configure()`.
3. Call `FirebaseConfiguration.configure()` from [PlaySnapApp.swift](/Users/andythang/personal-project/PlaySnap/App/PlaySnapApp.swift).

## 7. First milestone target

Once the project opens successfully, the first implementation target should be:

1. Replace `StubAuthService` with Firebase Auth
2. Persist the current user to Firestore
3. Complete the profile flow

## 8. Current scaffold

The repo already includes:

- App router and app shell
- Auth, onboarding, feed, notifications, and profile screens
- Core models and service interfaces
- Widget storage and widget placeholder files
- Firebase path helpers and camera permission placeholder

The next coding step after opening in Xcode is to wire Milestone 1, not to redesign the structure again.
