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

    func updateProfile(name: String, sport: Sport) async throws -> AppUser {
        let currentUser = try await requireCurrentUser()
        try await authGateway.updateCurrentUserDisplayName(name)
        return try await sessionStore.updateProfile(userID: currentUser.id, name: name, sport: sport)
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
