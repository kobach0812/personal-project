import Foundation

actor StubGameService: GameServicing {
    private var games: [Game] = []
    private var registrations: [String: [Registration]] = [:]   // sessionID → registrations

    // MARK: - Game lifecycle

    func createGame(squadID: String, createdBy: String, title: String, players: [GamePlayer]) async throws -> Game {
        let t = Game(
            id: UUID().uuidString, squadID: squadID, createdBy: createdBy,
            createdAt: .now, title: title, status: .active,
            players: players, activeDayID: nil, sessions: []
        )
        games.append(t)
        return t
    }

    func fetchGames(squadID: String) async throws -> [Game] {
        games
            .filter { $0.squadID == squadID }
            .sorted { lhs, rhs in
                if (lhs.status == .active) != (rhs.status == .active) { return lhs.status == .active }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func endGame(_ game: Game) async throws {
        var t = game
        t.status = .finished
        upsertGame(t)
    }

    // MARK: - Roster management

    func setGameRoster(_ players: [GamePlayer], for game: Game) async throws -> Game {
        var t = game
        t.players = players
        upsertGame(t)
        return t
    }

    func removePlayer(playerID: String, from game: Game) async throws -> Game {
        var t = game
        t.players.removeAll { $0.id == playerID }
        upsertGame(t)
        return t
    }

    func addPlayers(_ newPlayers: [GamePlayer], to game: Game) async throws -> Game {
        var t = game
        let existingUserIDs = Set(t.players.compactMap(\.userID))
        let existingNames   = Set(t.players.filter { $0.userID == nil }.map(\.name))
        for p in newPlayers {
            if let uid = p.userID { if !existingUserIDs.contains(uid) { t.players.append(p) } }
            else                  { if !existingNames.contains(p.name)  { t.players.append(p) } }
        }
        upsertGame(t)
        return t
    }

    // MARK: - Day / session lifecycle

    func startDay(for game: Game, courts: Int, players: [GamePlayer],
                  mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Game, GameSession) {
        let existingSessions = games.first(where: { $0.id == game.id })?.sessions ?? []
        var session = GameSession(
            id: UUID().uuidString,
            gameID: game.id,
            squadID: game.squadID,
            createdBy: game.createdBy,
            createdAt: .now,
            title: "Day \(existingSessions.count + 1)",
            status: .active,
            courts: courts,
            players: players,
            currentRound: [],
            roundNumber: 0,
            matchCounter: 0,
            completedMatches: [],
            partnerships: [:],
            participantUserIDs: players.compactMap(\.userID),
            endedAt: nil,
            scheduledStart: nil,
            location: nil,
            mode: mode,
            fixedTeams: fixedTeams
        )
        session.currentRound = mode == .fixedTeams
            ? GameRotationEngine.generateFixedTeamRound(session: session)
            : GameRotationEngine.fillAllCourts(session: session)

        var t = game
        t.activeDayID = session.id
        t.sessions.append(session)
        upsertGame(t)
        return (t, session)
    }

    func endDay(_ session: GameSession, for game: Game) async throws -> Game {
        var updatedSession = session
        updatedSession.status = .finished
        updatedSession.endedAt = .now

        var t = game
        t.activeDayID = nil
        t.players = mergeStats(into: t.players, from: session.players)
        upsertSession(updatedSession)
        upsertGame(t)
        return t
    }

    func fetchSessions(for game: Game) async throws -> [GameSession] {
        games.first(where: { $0.id == game.id })?.sessions ?? []
    }

    func fetchMatches(for session: GameSession) async throws -> [GameMatch] {
        games
            .first(where: { $0.id == session.gameID })?
            .sessions.first(where: { $0.id == session.id })?
            .completedMatches ?? []
    }

    // MARK: - In-session operations

    nonisolated func observeSession(squadID: String, gameID: String, sessionID: String) -> AsyncStream<GameSession> {
        AsyncStream { continuation in continuation.finish() }
    }

    func generateNextRound(for session: GameSession) async throws -> GameSession {
        var updated = session
        updated.currentRound = session.mode == .fixedTeams
            ? GameRotationEngine.generateFixedTeamRound(session: updated)
            : GameRotationEngine.fillAllCourts(session: updated)
        upsertSession(updated)
        return updated
    }

    func recordResult(for session: GameSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> GameSession {
        guard let match = session.currentRound.first(where: { $0.id == matchID }) else { return session }

        var updated = session
        updated.matchCounter += 1
        updated.players = GameRotationEngine.applyResult(
            players: updated.players, match: match,
            winner: winner, matchCounter: updated.matchCounter
        )
        updated.partnerships = GameRotationEngine.updatePartnerships(updated.partnerships, match: match)

        var archived = match
        archived.winnerTeam = winner; archived.teamAScore = scoreA
        archived.teamBScore = scoreB; archived.completedAt = .now
        updated.completedMatches.insert(archived, at: 0)

        updated.currentRound.removeAll { $0.id == matchID }
        let nextMatch = updated.mode == .fixedTeams
            ? GameRotationEngine.nextFixedTeamMatch(court: match.court, session: updated)
            : GameRotationEngine.generateMatchForCourt(court: match.court, session: updated)
        if let next = nextMatch {
            updated.currentRound.append(next)
        }
        upsertSession(updated)
        return updated
    }

    func updatePlayers(_ players: [GamePlayer], for session: GameSession) async throws -> GameSession {
        var updated = session
        updated.players = players
        upsertSession(updated)
        return updated
    }

    // MARK: - Participant self-actions

    func setSelfBench(playerID: String, isActive: Bool, for session: GameSession) async throws -> GameSession {
        guard var players = games
            .first(where: { $0.id == session.gameID })?
            .sessions.first(where: { $0.id == session.id })?
            .players,
              let idx = players.firstIndex(where: { $0.id == playerID })
        else { return session }
        players[idx].isActive = isActive
        return try await updatePlayers(players, for: session)
    }

    // MARK: - Fixed teams

    func setFixedTeams(_ teams: [FixedTeam], for session: GameSession) async throws -> GameSession {
        var updated = session
        updated.mode = .fixedTeams
        updated.fixedTeams = teams
        upsertSession(updated)
        return updated
    }

    // MARK: - Scheduled day lifecycle

    func scheduleSession(for game: Game, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> GameSession {
        let session = GameSession(
            id: UUID().uuidString, gameID: game.id, squadID: game.squadID,
            createdBy: game.createdBy, createdAt: .now, title: title,
            status: .scheduled, courts: courts, players: [], currentRound: [],
            roundNumber: 0, matchCounter: 0, completedMatches: [], partnerships: [:],
            participantUserIDs: [], endedAt: nil, scheduledStart: scheduledStart, location: location,
            mode: .rotation, fixedTeams: []
        )
        var t = game
        t.sessions.append(session)
        upsertGame(t)
        return session
    }

    func cancelScheduledSession(_ session: GameSession) async throws -> GameSession {
        var updated = session
        updated.status = .cancelled
        upsertSession(updated)
        return updated
    }

    func startScheduledSession(_ session: GameSession, courts: Int, players: [GamePlayer]) async throws -> GameSession {
        var updated = session
        updated.status = .active
        updated.courts = courts
        updated.players = players
        updated.participantUserIDs = players.compactMap(\.userID)
        updated.currentRound = GameRotationEngine.fillAllCourts(session: updated)
        upsertSession(updated)
        return updated
    }

    // MARK: - RSVP

    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: GameSession) async throws {
        var regs = registrations[session.id] ?? []
        if let idx = regs.firstIndex(where: { $0.id == userID }) {
            regs[idx].status = status
        } else {
            regs.append(Registration(id: userID, userID: userID, name: name, status: status,
                                     registeredAt: .now, checkedInAt: nil, addedToRoster: false))
        }
        registrations[session.id] = regs
    }

    // MARK: - Check-in

    func checkInPlayer(userID: String, name: String, in session: GameSession) async throws -> GameSession {
        var regs = registrations[session.id] ?? []
        if let idx = regs.firstIndex(where: { $0.id == userID }) {
            regs[idx].checkedInAt = .now
        } else {
            regs.append(Registration(id: userID, userID: userID, name: name, status: .yes,
                                     registeredAt: .now, checkedInAt: .now, addedToRoster: false))
        }
        registrations[session.id] = regs

        // If session is active, immediately add to roster
        if session.status == .active {
            let newPlayer = GamePlayer(id: UUID().uuidString, name: name, userID: userID,
                                             played: 0, wins: 0, losses: 0, lastPlayedAt: 0, isActive: true)
            var updated = session
            updated.players.append(newPlayer)
            updated.participantUserIDs.append(userID)
            if let idx = registrations[session.id]?.firstIndex(where: { $0.id == userID }) {
                registrations[session.id]?[idx].addedToRoster = true
            }
            upsertSession(updated)
            return updated
        }
        return session
    }

    nonisolated func observeRegistrations(for session: GameSession) -> AsyncStream<[Registration]> {
        AsyncStream { continuation in continuation.finish() }
    }

    func fetchNextScheduledSession(squadID: String) async throws -> GameSession? {
        let now = Date.now
        let allSessions = games
            .filter { $0.squadID == squadID }
            .flatMap { $0.sessions }
        let upcoming = allSessions.filter { session in
            session.status == .scheduled && (session.scheduledStart ?? .distantFuture) > now
        }
        return upcoming.sorted { a, b in
            (a.scheduledStart ?? .distantFuture) < (b.scheduledStart ?? .distantFuture)
        }.first
    }

    // MARK: - Private helpers

    private func upsertGame(_ t: Game) {
        if let idx = games.firstIndex(where: { $0.id == t.id }) { games[idx] = t }
        else { games.append(t) }
    }

    private func upsertSession(_ session: GameSession) {
        guard let ti = games.firstIndex(where: { $0.id == session.gameID }) else { return }
        if let si = games[ti].sessions.firstIndex(where: { $0.id == session.id }) {
            games[ti].sessions[si] = session
        } else {
            games[ti].sessions.append(session)
        }
    }

    /// Adds day player stats into the game's cumulative roster, matched by userID or name.
    private func mergeStats(into base: [GamePlayer], from day: [GamePlayer]) -> [GamePlayer] {
        var result = base
        for sp in day where sp.played > 0 {
            if let uid = sp.userID, let idx = result.firstIndex(where: { $0.userID == uid }) {
                result[idx].played += sp.played
                result[idx].wins   += sp.wins
                result[idx].losses += sp.losses
            } else if sp.userID == nil,
                      let idx = result.firstIndex(where: { $0.name == sp.name && $0.userID == nil }) {
                result[idx].played += sp.played
                result[idx].wins   += sp.wins
                result[idx].losses += sp.losses
            }
        }
        return result
    }
}
