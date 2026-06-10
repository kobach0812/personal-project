import Foundation

enum GameServiceError: Error {
    case notAuthenticated
    case noSquad
    case gameNotFound
    case sessionNotFound
}

protocol GameServicing: Sendable {

    // MARK: - Game lifecycle

    func createGame(squadID: String, createdBy: String, title: String, players: [GamePlayer]) async throws -> Game
    func fetchGames(squadID: String) async throws -> [Game]
    func endGame(_ game: Game) async throws

    // MARK: - Roster management

    /// Adds new players to the game roster (dedup by userID / name).
    func addPlayers(_ newPlayers: [GamePlayer], to game: Game) async throws -> Game

    /// Overwrites the full game roster. Used to persist guest name edits and mid-game additions.
    func setGameRoster(_ players: [GamePlayer], for game: Game) async throws -> Game

    /// Removes a player from the game roster entirely. Any in-progress day keeps
    /// its own copy of the player — only the game-level roster is affected.
    func removePlayer(playerID: String, from game: Game) async throws -> Game

    // MARK: - Day / session lifecycle

    /// Creates a new active day session within the game.
    func startDay(for game: Game, courts: Int, players: [GamePlayer],
                  mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Game, GameSession)
    /// Ends the day: marks session finished, merges day stats into game cumulative stats.
    func endDay(_ session: GameSession, for game: Game) async throws -> Game
    func fetchSessions(for game: Game) async throws -> [GameSession]
    func fetchMatches(for session: GameSession) async throws -> [GameMatch]

    // MARK: - In-session operations

    /// Real-time observer for the session document. Yields on every remote change.
    /// completedMatches in yielded sessions is always empty — load separately via fetchMatches.
    func observeSession(squadID: String, gameID: String, sessionID: String) -> AsyncStream<GameSession>

    func generateNextRound(for session: GameSession) async throws -> GameSession
    func recordResult(for session: GameSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> GameSession
    /// Persists a changed players array (used for bench / restore / remove).
    func updatePlayers(_ players: [GamePlayer], for session: GameSession) async throws -> GameSession

    // MARK: - Participant self-actions

    /// Participant toggles their own isActive flag. VM enforces caller only touches their own row.
    func setSelfBench(playerID: String, isActive: Bool, for session: GameSession) async throws -> GameSession

    // MARK: - Fixed teams

    /// Sets (or replaces) the fixed teams for a session and switches mode to .fixedTeams.
    /// Current round is not modified — new engine applies from the next freed court.
    func setFixedTeams(_ teams: [FixedTeam], for session: GameSession) async throws -> GameSession

    // MARK: - Scheduled day lifecycle

    /// Creates a session in `scheduled` status — no roster yet.
    func scheduleSession(for game: Game, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> GameSession

    /// Host cancels a scheduled day before it starts.
    func cancelScheduledSession(_ session: GameSession) async throws -> GameSession

    /// Host transitions scheduled → active with the confirmed courts count and player list.
    func startScheduledSession(_ session: GameSession, courts: Int, players: [GamePlayer]) async throws -> GameSession

    // MARK: - RSVP (participant self-action)

    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: GameSession) async throws

    // MARK: - Check-in (host only)

    /// Stamps checkedInAt. If session is active, also appends player to session.players[].
    func checkInPlayer(userID: String, name: String, in session: GameSession) async throws -> GameSession

    func observeRegistrations(for session: GameSession) -> AsyncStream<[Registration]>

    // MARK: - Next scheduled session (for Feed banner)

    func fetchNextScheduledSession(squadID: String) async throws -> GameSession?
}
