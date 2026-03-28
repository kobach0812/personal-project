import Foundation

struct AppSession: Equatable, Sendable {
    let userID: String
    var hasCompletedProfile: Bool
    var hasJoinedSquad: Bool
    var hasSeenWidgetIntro: Bool
}

enum AuthServiceError: Error {
    case missingSession
}

protocol AuthServicing {
    func restoreSession() async throws -> AppSession?
    func signInWithApple() async throws -> AppSession
    func completeProfile(name: String, sport: Sport) async throws -> AppSession
    func markJoinedSquad() async throws -> AppSession
    func markSeenWidgetIntro() async throws -> AppSession
    func signOut() async throws
}

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
