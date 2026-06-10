# Maintainable And Extendable App Rules

This document is the engineering rulebook for PlaySnap.

The goal is simple:

- make the app easy to change
- make new features cheap to add
- make bugs easier to isolate
- make the codebase safe to grow as a solo founder and later as a team

## 1. Non-Negotiable Rules

- `Views` render state and send user actions only.
- `ViewModels` coordinate UI logic only.
- `Domain` owns business models and protocol contracts.
- `Data` owns Firebase, local persistence, and external SDK implementations.
- `Infrastructure` owns platform wrappers like camera or OS-specific adapters.
- `PreviewSupport` owns fixture and preview data only.
- No feature screen may talk directly to Firebase, Storage, Firestore, WidgetKit, or `UserDefaults`.
- Only UI-facing types should be `@MainActor`.
- Do not turn on project-wide actor isolation.
- Prefer constructor injection or environment injection over hard-coded dependencies.

## 2. Architecture Standard

Use `SwiftUI + MVVM + Domain/Data separation`.

This means:

- `View`: display only
- `ViewModel`: state, validation, user actions, async orchestration
- `Domain`: app rules, contracts, models
- `Data`: Firebase services, local services, stubs

What to avoid:

- massive views
- business logic inside SwiftUI screens
- direct SDK calls from feature code
- global singletons for feature dependencies

## 3. File And Module Rules

- Each file should have one clear purpose.
- If a file starts doing two jobs, split it.
- Group code by `feature` first, not by generic type only.
- Shared code must be truly shared. If it is used by one feature, keep it inside that feature.
- Keep cross-target shared code small and explicit.

Good examples:

- `Features/Auth/AuthView.swift`
- `Features/Auth/AuthViewModel.swift`
- `Domain/Services/AuthService.swift`
- `Data/Firebase/FirebaseAuthService.swift`

## 4. Dependency Rules

- Depend on protocols, not concrete implementations.
- Never create Firebase or service objects inline inside a feature view model.
- Wire dependencies in the app environment or a container.
- New integrations must be added behind a protocol first.

Bad:

```swift
final class FeedViewModel {
    let service = Firestore.firestore()
}
```

Good:

```swift
final class FeedViewModel {
    private let playService: PlayServicing

    init(playService: PlayServicing) {
        self.playService = playService
    }
}
```

## 5. Model Rules

- Domain models should stay simple, `Codable`, `Equatable`, and `Sendable` when possible.
- Do not mix preview data into production models.
- Do not put Firebase SDK types inside domain models.
- Prefer explicit fields over vague dictionaries.
- Keep write-heavy collections normalized. Do not embed large mutable arrays where contention is likely.

## 6. Growth Rules

Before adding a new feature, check:

1. Does it belong to an existing feature or a new feature folder?
2. Does it require a new domain protocol?
3. Does it require a Firebase implementation, a local implementation, or both?
4. Does it change routing or only one screen?
5. Can it be tested without launching the whole app?

If the answer to `5` is no, the design is usually too coupled.

## 7. Refactor Triggers

Refactor when:

- a view model becomes hard to explain in one sentence
- a file grows beyond roughly `200-300` lines without a good reason
- the same logic appears in more than one place
- a feature needs knowledge of another feature's internal details
- changing one screen breaks unrelated areas
- you need comments to explain confusing structure instead of improving the structure

## 8. Testing Rules

Minimum testing priority:

1. business logic
2. view model state transitions
3. auth flow
4. upload flow
5. critical onboarding flow

Write tests for anything that would be expensive to break later.

## 9. Product Rules For A Founder

- Build the smallest system that proves the core loop.
- Do not add infrastructure before a real feature needs it.
- Do not add abstraction for imaginary future use cases.
- Do add boundaries early where vendor lock-in or complexity is real.
- Optimize for fast iteration, but never by collapsing all layers together.

The rule is:

`simple internally, strict at the boundaries`

## 10. PlaySnap-Specific Rules

- Squad-sharing remains the core product loop.
- Discovery features must not leak into MVP architecture unless they have a clear home.
- Widget data stays payload-based and small.
- Auth, storage, feed, notifications, and widget sync stay replaceable behind protocols.
- Firebase is an implementation detail, not the architecture.

## 11. Pre-Merge Checklist

Before considering a change complete, check:

- Does the new code fit the existing `Domain -> Data -> Features` structure?
- Did I avoid direct SDK calls from the view or view model?
- Did I add or update a protocol if behavior changed?
- Did I keep fixture data out of production models?
- Did I keep naming clear and specific?
- Can the flow fail safely?
- Can someone else understand this change quickly in one reading?

If not, the change is not ready.
