import Foundation

actor FirebaseUserProfileService: UserProfileServicing {
    private let authGateway: FirebaseAuthGateway
    private let sessionStore: FirebaseSessionDocumentStore

    init(
        authGateway: FirebaseAuthGateway = FirebaseAuthGateway(),
        sessionStore: FirebaseSessionDocumentStore = FirebaseSessionDocumentStore()
    ) {
        self.authGateway = authGateway
        self.sessionStore = sessionStore
    }

    func fetchCurrentUser() async throws -> AppUser? {
        guard let currentUser = try await authGateway.currentUser() else {
            return nil
        }

        return try await sessionStore.fetchCurrentUser(for: currentUser)
    }

    func updateProfile(name: String) async throws -> AppUser {
        let currentUser = try await requireCurrentUser()
        try await authGateway.updateCurrentUserDisplayName(name)
        return try await sessionStore.updateProfile(userID: currentUser.id, name: name)
    }

    func fetchUsers(ids: [String]) async throws -> [AppUser] {
        guard !ids.isEmpty else { return [] }
        let store = sessionStore
        return try await withThrowingTaskGroup(of: AppUser?.self) { group in
            for id in ids {
                group.addTask { try await store.fetchUser(id: id) }
            }
            var users: [AppUser] = []
            for try await user in group {
                if let user { users.append(user) }
            }
            return users
        }
    }

    func updateAvatar(url: URL) async throws -> AppUser {
        let currentUser = try await requireCurrentUser()
        return try await sessionStore.updateAvatar(userID: currentUser.id, url: url)
    }
}

private extension FirebaseUserProfileService {
    func requireCurrentUser() async throws -> FirebaseAuthenticatedUser {
        guard let currentUser = try await authGateway.currentUser() else {
            throw AuthServiceError.missingSession
        }

        return currentUser
    }
}
