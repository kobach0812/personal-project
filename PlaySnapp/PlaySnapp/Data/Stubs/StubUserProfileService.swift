import Foundation

actor StubUserProfileService: UserProfileServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func fetchCurrentUser() async throws -> AppUser? {
        await sessionStore.fetchCurrentUser()
    }

    func fetchUsers(ids: [String]) async throws -> [AppUser] {
        // In development only the signed-in user exists. Return them if their ID is requested.
        guard let me = await sessionStore.fetchCurrentUser(), ids.contains(me.id) else { return [] }
        return [me]
    }

    func updateProfile(name: String) async throws -> AppUser {
        try await sessionStore.updateProfile(name: name)
    }

    func updateAvatar(url: URL) async throws -> AppUser {
        try await sessionStore.updateAvatar(url: url)
    }
}
