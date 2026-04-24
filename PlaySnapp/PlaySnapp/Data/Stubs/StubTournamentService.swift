import Foundation

actor StubTournamentService: TournamentServicing {
    private var sessions: [TournamentSession] = []

    func createSession(squadID: String, createdBy: String, title: String, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession {
        var session = TournamentSession(
            id: UUID().uuidString,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: .now,
            title: title,
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
        sessions.append(session)
        return session
    }

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        var updated = session
        updated.currentRound = TournamentRotationEngine.fillAllCourts(session: updated)
        upsert(updated)
        return updated
    }

    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession {
        guard let match = session.currentRound.first(where: { $0.id == matchID }) else { return session }

        var updated = session
        updated.matchCounter += 1
        updated.players = TournamentRotationEngine.applyResult(
            players: updated.players,
            match: match,
            winner: winner,
            matchCounter: updated.matchCounter
        )
        updated.partnerships = TournamentRotationEngine.updatePartnerships(updated.partnerships, match: match)

        var archived = match
        archived.winnerTeam = winner
        archived.teamAScore = scoreA
        archived.teamBScore = scoreB
        archived.completedAt = .now
        updated.completedMatches.insert(archived, at: 0)

        updated.currentRound.removeAll { $0.id == matchID }
        if let next = TournamentRotationEngine.generateMatchForCourt(court: match.court, session: updated) {
            updated.currentRound.append(next)
        }
        upsert(updated)
        return updated
    }

    func endSession(_ session: TournamentSession) async throws {
        var finished = session
        finished.status = .finished
        upsert(finished)
    }

    func fetchSessions(squadID: String) async throws -> [TournamentSession] {
        sessions
            .filter { $0.squadID == squadID }
            .sorted { lhs, rhs in
                if (lhs.status == .active) != (rhs.status == .active) { return lhs.status == .active }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func fetchMatches(squadID: String, sessionID: String) async throws -> [TournamentMatch] {
        sessions.first(where: { $0.id == sessionID })?.completedMatches ?? []
    }

    // MARK: - Private

    private func upsert(_ session: TournamentSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i] = session
        }
    }
}
