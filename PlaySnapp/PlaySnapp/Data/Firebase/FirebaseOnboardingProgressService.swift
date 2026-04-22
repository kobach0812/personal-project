import Foundation

actor FirebaseOnboardingProgressService: OnboardingProgressServicing {
    private let authGateway: FirebaseAuthGateway
    private let sessionStore: FirebaseSessionDocumentStore

    init(
        authGateway: FirebaseAuthGateway = FirebaseAuthGateway(),
        sessionStore: FirebaseSessionDocumentStore = FirebaseSessionDocumentStore()
    ) {
        self.authGateway = authGateway
        self.sessionStore = sessionStore
    }

    func completeProfile(name: String) async throws -> AppSession {
        let currentUser = try await requireCurrentUser()
        try await authGateway.updateCurrentUserDisplayName(name)
        return try await sessionStore.completeProfile(userID: currentUser.id, name: name)
    }

    func markJoinedSquad() async throws -> AppSession {
        let currentUser = try await requireCurrentUser()
        return try await sessionStore.markJoinedSquad(userID: currentUser.id)
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        let currentUser = try await requireCurrentUser()
        // Write locally first so the flag survives even if the Firestore call below fails.
        // session(from:userID:) merges this local flag on the next restoreSession() call,
        // preventing the user from being shown the widget intro again after a network error.
        LocalOnboardingFlagStore.set(.hasSeenWidgetIntro, for: currentUser.id)
        return try await sessionStore.markSeenWidgetIntro(userID: currentUser.id)
    }
}

private extension FirebaseOnboardingProgressService {
    func requireCurrentUser() async throws -> FirebaseAuthenticatedUser {
        guard let currentUser = try await authGateway.currentUser() else {
            throw AuthServiceError.missingSession
        }

        return currentUser
    }
}
