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
}
