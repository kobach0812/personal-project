import Foundation

enum TournamentServiceError: Error {
    case notAuthenticated
    case noSquad
    case sessionNotFound
}

protocol TournamentServicing: Sendable {
    func createSession(squadID: String, createdBy: String, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession
    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession
    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession
    func endSession(_ session: TournamentSession) async throws
    func fetchActiveSession(squadID: String) async throws -> TournamentSession?
}
