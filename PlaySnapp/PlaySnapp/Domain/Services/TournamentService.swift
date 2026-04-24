import Foundation

enum TournamentServiceError: Error {
    case notAuthenticated
    case noSquad
    case sessionNotFound
}

protocol TournamentServicing: Sendable {
    func createSession(squadID: String, createdBy: String, title: String, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession
    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession
    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession
    func endSession(_ session: TournamentSession) async throws
    /// Returns all sessions for the squad, active ones first, then by createdAt descending.
    func fetchSessions(squadID: String) async throws -> [TournamentSession]
    /// Fetches completed matches from the persistent `matches` subcollection, newest first.
    func fetchMatches(squadID: String, sessionID: String) async throws -> [TournamentMatch]
}
