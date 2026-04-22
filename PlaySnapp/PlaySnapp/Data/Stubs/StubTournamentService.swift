import Foundation

actor StubTournamentService: TournamentServicing {
    func createSession(squadID: String, createdBy: String, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession {
        var session = TournamentSession(
            id: UUID().uuidString,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: .now,
            status: .active,
            courts: courts,
            players: players,
            currentRound: [],
            roundNumber: 0,
            matchCounter: 0,
            completedMatches: [],
            partnerships: [:]
        )
        session.currentRound = TournamentRotationEngine.fillAllCourts(session: session)
        return session
    }

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        var updated = session
        updated.currentRound = TournamentRotationEngine.fillAllCourts(session: updated)
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
        return updated
    }

    func endSession(_ session: TournamentSession) async throws {}

    func fetchActiveSession(squadID: String) async throws -> TournamentSession? { nil }
}
