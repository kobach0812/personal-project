import Foundation

actor StubTournamentService: TournamentServicing {
    private var tournaments: [Tournament] = []

    // MARK: - Tournament lifecycle

    func createTournament(squadID: String, createdBy: String, title: String, players: [TournamentPlayer]) async throws -> Tournament {
        let t = Tournament(
            id: UUID().uuidString, squadID: squadID, createdBy: createdBy,
            createdAt: .now, title: title, status: .active,
            players: players, activeDayID: nil, sessions: []
        )
        tournaments.append(t)
        return t
    }

    func fetchTournaments(squadID: String) async throws -> [Tournament] {
        tournaments
            .filter { $0.squadID == squadID }
            .sorted { lhs, rhs in
                if (lhs.status == .active) != (rhs.status == .active) { return lhs.status == .active }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func endTournament(_ tournament: Tournament) async throws {
        var t = tournament
        t.status = .finished
        upsertTournament(t)
    }

    // MARK: - Roster management

    func setTournamentRoster(_ players: [TournamentPlayer], for tournament: Tournament) async throws -> Tournament {
        var t = tournament
        t.players = players
        upsertTournament(t)
        return t
    }

    func addPlayers(_ newPlayers: [TournamentPlayer], to tournament: Tournament) async throws -> Tournament {
        var t = tournament
        let existingUserIDs = Set(t.players.compactMap(\.userID))
        let existingNames   = Set(t.players.filter { $0.userID == nil }.map(\.name))
        for p in newPlayers {
            if let uid = p.userID { if !existingUserIDs.contains(uid) { t.players.append(p) } }
            else                  { if !existingNames.contains(p.name)  { t.players.append(p) } }
        }
        upsertTournament(t)
        return t
    }

    // MARK: - Day / session lifecycle

    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer]) async throws -> (Tournament, TournamentSession) {
        let existingSessions = tournaments.first(where: { $0.id == tournament.id })?.sessions ?? []
        var session = TournamentSession(
            id: UUID().uuidString,
            tournamentID: tournament.id,
            squadID: tournament.squadID,
            createdBy: tournament.createdBy,
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
            participantUserIDs: players.compactMap(\.userID)
        )
        session.currentRound = TournamentRotationEngine.fillAllCourts(session: session)

        var t = tournament
        t.activeDayID = session.id
        t.sessions.append(session)
        upsertTournament(t)
        return (t, session)
    }

    func endDay(_ session: TournamentSession, for tournament: Tournament) async throws -> Tournament {
        var updatedSession = session
        updatedSession.status = .finished
        updatedSession.endedAt = .now

        var t = tournament
        t.activeDayID = nil
        t.players = mergeStats(into: t.players, from: session.players)
        upsertSession(updatedSession)
        upsertTournament(t)
        return t
    }

    func fetchSessions(for tournament: Tournament) async throws -> [TournamentSession] {
        tournaments.first(where: { $0.id == tournament.id })?.sessions ?? []
    }

    func fetchMatches(for session: TournamentSession) async throws -> [TournamentMatch] {
        tournaments
            .first(where: { $0.id == session.tournamentID })?
            .sessions.first(where: { $0.id == session.id })?
            .completedMatches ?? []
    }

    // MARK: - In-session operations

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        var updated = session
        updated.currentRound = TournamentRotationEngine.fillAllCourts(session: updated)
        upsertSession(updated)
        return updated
    }

    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession {
        guard let match = session.currentRound.first(where: { $0.id == matchID }) else { return session }

        var updated = session
        updated.matchCounter += 1
        updated.players = TournamentRotationEngine.applyResult(
            players: updated.players, match: match,
            winner: winner, matchCounter: updated.matchCounter
        )
        updated.partnerships = TournamentRotationEngine.updatePartnerships(updated.partnerships, match: match)

        var archived = match
        archived.winnerTeam = winner; archived.teamAScore = scoreA
        archived.teamBScore = scoreB; archived.completedAt = .now
        updated.completedMatches.insert(archived, at: 0)

        updated.currentRound.removeAll { $0.id == matchID }
        if let next = TournamentRotationEngine.generateMatchForCourt(court: match.court, session: updated) {
            updated.currentRound.append(next)
        }
        upsertSession(updated)
        return updated
    }

    func updatePlayers(_ players: [TournamentPlayer], for session: TournamentSession) async throws -> TournamentSession {
        var updated = session
        updated.players = players
        upsertSession(updated)
        return updated
    }

    // MARK: - Private helpers

    private func upsertTournament(_ t: Tournament) {
        if let idx = tournaments.firstIndex(where: { $0.id == t.id }) { tournaments[idx] = t }
        else { tournaments.append(t) }
    }

    private func upsertSession(_ session: TournamentSession) {
        guard let ti = tournaments.firstIndex(where: { $0.id == session.tournamentID }) else { return }
        if let si = tournaments[ti].sessions.firstIndex(where: { $0.id == session.id }) {
            tournaments[ti].sessions[si] = session
        } else {
            tournaments[ti].sessions.append(session)
        }
    }

    /// Adds day player stats into the tournament's cumulative roster, matched by userID or name.
    private func mergeStats(into base: [TournamentPlayer], from day: [TournamentPlayer]) -> [TournamentPlayer] {
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
