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
    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer],
                  mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Tournament, TournamentSession)
    /// Ends the day: marks session finished, merges day stats into tournament cumulative stats.
    func endDay(_ session: TournamentSession, for tournament: Tournament) async throws -> Tournament
    func fetchSessions(for tournament: Tournament) async throws -> [TournamentSession]
    func fetchMatches(for session: TournamentSession) async throws -> [TournamentMatch]

    // MARK: - In-session operations

    /// Real-time observer for the session document. Yields on every remote change.
    /// completedMatches in yielded sessions is always empty — load separately via fetchMatches.
    func observeSession(squadID: String, tournamentID: String, sessionID: String) -> AsyncStream<TournamentSession>

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession
    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession
    /// Persists a changed players array (used for bench / restore / remove).
    func updatePlayers(_ players: [TournamentPlayer], for session: TournamentSession) async throws -> TournamentSession

    // MARK: - Participant self-actions

    /// Participant toggles their own isActive flag. VM enforces caller only touches their own row.
    func setSelfBench(playerID: String, isActive: Bool, for session: TournamentSession) async throws -> TournamentSession

    // MARK: - Fixed teams

    /// Sets (or replaces) the fixed teams for a session and switches mode to .fixedTeams.
    /// Current round is not modified — new engine applies from the next freed court.
    func setFixedTeams(_ teams: [FixedTeam], for session: TournamentSession) async throws -> TournamentSession

    // MARK: - Scheduled day lifecycle

    /// Creates a session in `scheduled` status — no roster yet.
    func scheduleSession(for tournament: Tournament, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> TournamentSession

    /// Host cancels a scheduled day before it starts.
    func cancelScheduledSession(_ session: TournamentSession) async throws -> TournamentSession

    /// Host transitions scheduled → active with the confirmed courts count and player list.
    func startScheduledSession(_ session: TournamentSession, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession

    // MARK: - RSVP (participant self-action)

    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: TournamentSession) async throws

    // MARK: - Check-in (host only)

    /// Stamps checkedInAt. If session is active, also appends player to session.players[].
    func checkInPlayer(userID: String, name: String, in session: TournamentSession) async throws -> TournamentSession

    func observeRegistrations(for session: TournamentSession) -> AsyncStream<[Registration]>

    // MARK: - Next scheduled session (for Feed banner)

    func fetchNextScheduledSession(squadID: String) async throws -> TournamentSession?
}
