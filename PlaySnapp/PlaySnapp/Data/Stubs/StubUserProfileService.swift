import Foundation

actor StubUserProfileService: UserProfileServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func fetchCurrentUser() async throws -> AppUser? {
        await sessionStore.fetchCurrentUser()
    }

    func updateProfile(name: String) async throws -> AppUser {
        try await sessionStore.updateProfile(name: name)
    }

    func updateAvatar(url: URL) async throws -> AppUser {
        try await sessionStore.updateAvatar(url: url)
    }
}
