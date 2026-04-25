import Foundation

enum TournamentServiceError: Error {
    case notAuthenticated
    case noSquad
    case tournamentNotFound
    case sessionNotFound
}

protocol TournamentServicing: Sendable {

    // MARK: - Tournament lifecycle

    func createTournament(squadID: String, createdBy: String, title: String, players: [TournamentPlayer]) async throws -> Tournament
    func fetchTournaments(squadID: String) async throws -> [Tournament]
    func endTournament(_ tournament: Tournament) async throws

    // MARK: - Roster management

    /// Adds new players to the tournament roster (dedup by userID / name).
    func addPlayers(_ newPlayers: [TournamentPlayer], to tournament: Tournament) async throws -> Tournament

    /// Overwrites the full tournament roster. Used to persist guest name edits and mid-tournament additions.
    func setTournamentRoster(_ players: [TournamentPlayer], for tournament: Tournament) async throws -> Tournament

    // MARK: - Day / session lifecycle

    /// Creates a new active day session within the tournament.
    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer]) async throws -> (Tournament, TournamentSession)
    /// Ends the day: marks session finished, merges day stats into tournament cumulative stats.
    func endDay(_ session: TournamentSession, for tournament: Tournament) async throws -> Tournament
    func fetchSessions(for tournament: Tournament) async throws -> [TournamentSession]
    func fetchMatches(for session: TournamentSession) async throws -> [TournamentMatch]

    // MARK: - In-session operations

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession
    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession
    /// Persists a changed players array (used for bench / restore / remove).
    func updatePlayers(_ players: [TournamentPlayer], for session: TournamentSession) async throws -> TournamentSession
}
