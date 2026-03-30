import Foundation

actor StubAuthService: AuthServicing {
    private var session: AppSession?

    func restoreSession() async throws -> AppSession? {
        session
    }

    func signInWithApple() async throws -> AppSession {
        let nextSession = AppSession(
            userID: UUID().uuidString,
            hasCompletedProfile: false,
            hasJoinedSquad: false,
            hasSeenWidgetIntro: false
        )

        session = nextSession
        return nextSession
    }

    func completeProfile(name: String, sport: Sport) async throws -> AppSession {
        guard var current = session else {
            throw AuthServiceError.missingSession
        }

        current.hasCompletedProfile = true
        session = current
        return current
    }

    func markJoinedSquad() async throws -> AppSession {
        guard var current = session else {
            throw AuthServiceError.missingSession
        }

        current.hasJoinedSquad = true
        session = current
        return current
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        guard var current = session else {
            throw AuthServiceError.missingSession
        }

        current.hasSeenWidgetIntro = true
        session = current
        return current
    }

    func signOut() async throws {
        session = nil
    }
}
