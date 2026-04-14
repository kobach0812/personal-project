# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `PlaySnapp/PlaySnapp.xcodeproj` in Xcode. The project uses filesystem-synchronized groups — files added to the filesystem appear in Xcode automatically.

- **Build**: `Cmd+B` in Xcode (or `xcodebuild build -project PlaySnapp/PlaySnapp.xcodeproj -scheme PlaySnapp -destination 'platform=iOS Simulator,name=iPhone 16'`)
- **Run tests**: `Cmd+U` in Xcode (or `xcodebuild test -project PlaySnapp/PlaySnapp.xcodeproj -scheme PlaySnapp -destination 'platform=iOS Simulator,name=iPhone 16'`)
- **Run single test**: Use `xcodebuild test` with `-only-testing:PlaySnappTests/TestClassName/testMethodName`
- **Deployment target**: iOS 18.6
- **Swift version**: 5.0

### SPM Dependencies

Only one external dependency: `firebase-ios-sdk` >= 12.11.0 (FirebaseAuth, FirebaseCore, FirebaseFirestore, FirebaseMessaging, FirebaseStorage). Managed via Xcode's SPM integration, not a standalone Package.swift.

## Architecture

SwiftUI + MVVM with strict Domain/Data separation. The core rule: **simple internally, strict at the boundaries.**

### Layer Structure

| Layer | Location | Owns |
|-------|----------|------|
| Domain | `PlaySnapp/Domain/` | Protocol contracts (`*Servicing` suffix) and value-type models. No Firebase/SDK imports. |
| Data | `PlaySnapp/Data/` | Concrete implementations behind domain protocols. `Firebase*` for production, `Stub*` for development, `Local*` for platform services. |
| Features | `PlaySnapp/Features/` | SwiftUI views and `@MainActor ObservableObject` view models per feature. Views never import Firebase. |
| Infrastructure | `PlaySnapp/Infrastructure/` | Platform wrappers (e.g., `CameraManager` wrapping AVFoundation). |
| PreviewSupport | `PlaySnapp/PreviewSupport/` | Fixture data for SwiftUI previews only. |

### Dependency Injection

`AppEnvironment` is the service locator/DI container, injected as `@EnvironmentObject`. It is bootstrapped with one of two `AppDataSource` values:
- `.development` — all stub services with shared in-memory state
- `.firebasePrepared` — real Firebase auth/storage, stubs for squad/play/notifications

### Navigation

`AppRouter` drives phase-based navigation via a published `AppPhase` enum (`.loading` → `.auth` → `.profileSetup` → `.squadSetup` → `.widgetIntro` → `.main`). `RootView` switches on the phase. The main phase uses a `TabView` with 4 tabs (camera, feed, notifications, profile).

### Concurrency

- Services use Swift `actor` types for concurrency safety
- Only UI-facing types are `@MainActor` (views, view models, router, environment)
- No project-wide actor isolation
- Firebase implementations use `#if canImport(FirebaseAuth)` etc. so the project compiles without Firebase SDKs linked

## Naming Conventions

- Domain protocols: `*Servicing` (e.g., `AuthServicing`, `PlayServicing`)
- Firebase implementations: `Firebase*` (e.g., `FirebaseAuthService`)
- Stub implementations: `Stub*` (e.g., `StubAuthService`)
- Test doubles: `*Stub` (e.g., `AuthServiceStub`) — implemented as `actor` types
- Domain models: value types that are `Codable`, `Equatable`, `Sendable` when possible
- Error types: `*Error` enum conforming to `LocalizedError` (e.g., `AuthServiceError`)

## Testing

Tests use the **Swift Testing framework** (`import Testing`, `@Test`, `#expect`), not XCTest. Test doubles are in `PlaySnappTests/TestDoubles.swift`.

Current coverage: routing logic (`AppRouterTests`) and onboarding view models (`OnboardingViewModelTests`). No tests yet for Feed, Camera, Profile, or Data layer implementations.

## Widget Extension

- Target: `WidgetExtensionExtension` (bundle ID: `com.andythang.PlaySnapp.WidgetExtension`)
- Shared code: `AppGroupStore.swift` and `WidgetPayload` are included in both the app and widget targets via build file exception
- Widget reads from `UserDefaults(suiteName: "group.com.playsnap.shared")`
- Widget does NOT link Firebase — it only uses WidgetKit and SwiftUI

## Key Rules (from Documents/maintainable-extendable-app.md)

1. No feature screen may talk directly to Firebase, Storage, Firestore, WidgetKit, or UserDefaults
2. New integrations must be added behind a domain protocol first
3. Never create Firebase or service objects inline inside a feature view model
4. Keep fixture/preview data out of production models
5. Do not put Firebase SDK types inside domain models
6. Refactor when a view model exceeds roughly 200-300 lines or does more than one thing
7. Before adding a feature: check if it needs a new domain protocol, a new Data implementation, and whether it changes routing

## Setup Gaps

See `Documents/XCODE_SETUP.md` for remaining Xcode configuration steps:
- App Groups capability not yet configured (entitlements files are empty)
- Push Notifications and Background Modes capabilities not added
- `GoogleService-Info.plist` bundle ID (`test.andythang.PlaySnapp`) does not match target bundle ID (`com.andythang.PlaySnapp`)