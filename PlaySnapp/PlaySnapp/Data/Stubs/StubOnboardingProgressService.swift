import Foundation

actor StubOnboardingProgressService: OnboardingProgressServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func completeProfile(name: String) async throws -> AppSession {
        try await sessionStore.completeProfile(name: name)
    }

    func markJoinedSquad() async throws -> AppSession {
        try await sessionStore.markJoinedSquad()
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        try await sessionStore.markSeenWidgetIntro()
    }
}
