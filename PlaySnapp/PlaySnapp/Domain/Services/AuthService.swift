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
