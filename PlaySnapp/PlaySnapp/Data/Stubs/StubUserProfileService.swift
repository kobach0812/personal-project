import Foundation

actor StubUserProfileService: UserProfileServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func fetchCurrentUser() async throws -> AppUser? {
        await sessionStore.fetchCurrentUser()
    }
}
