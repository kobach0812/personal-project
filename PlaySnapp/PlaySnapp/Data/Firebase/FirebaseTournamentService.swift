import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseTournamentService: TournamentServicing {

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    func createSession(squadID: String, createdBy: String, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        let sessionID = UUID().uuidString
        var session = TournamentSession(
            id: sessionID,
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
        try await firestore
            .document(FirestorePaths.tournament(squadID, sessionID))
            .setData(sessionToDict(session))
        return session
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.currentRound = TournamentRotationEngine.fillAllCourts(session: updated)
        try await firestore
            .document(FirestorePaths.tournament(session.squadID, session.id))
            .updateData([
                "currentRound": updated.currentRound.map(matchToDict)
            ])
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
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

        let winnerIDs = winner == .teamA ? match.teamA : match.teamB
        let loserIDs  = winner == .teamA ? match.teamB : match.teamA

        let batch = firestore.batch()

        let sessionRef = firestore.document(FirestorePaths.tournament(session.squadID, session.id))
        batch.updateData([
            "currentRound": updated.currentRound.map(matchToDict),
            "players": updated.players.map(playerToDict),
            "partnerships": updated.partnerships,
            "matchCounter": updated.matchCounter
        ], forDocument: sessionRef)

        for id in winnerIDs + loserIDs {
            guard let player = updated.players.first(where: { $0.id == id }),
                  let userID = player.userID else { continue }
            let ref = firestore.document(FirestorePaths.leaderboardEntry(session.squadID, userID))
            let isWinner = winnerIDs.contains(id)
            batch.setData([
                "name": player.name,
                "totalPlayed": FieldValue.increment(Int64(1)),
                "totalWins": FieldValue.increment(Int64(isWinner ? 1 : 0)),
                "totalLosses": FieldValue.increment(Int64(isWinner ? 0 : 1))
            ], forDocument: ref, merge: true)
        }

        try await batch.commit()
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func endSession(_ session: TournamentSession) async throws {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournament(session.squadID, session.id))
            .updateData(["status": TournamentStatus.finished.rawValue])
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchActiveSession(squadID: String) async throws -> TournamentSession? {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.tournaments(squadID))
            .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { sessionFrom($0.data(), sessionID: $0.documentID) }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }
}

// MARK: - Serialization

private extension FirebaseTournamentService {
    func playerToDict(_ p: TournamentPlayer) -> [String: Any] {
        var d: [String: Any] = [
            "id": p.id, "name": p.name,
            "played": p.played, "wins": p.wins, "losses": p.losses,
            "lastPlayedAt": p.lastPlayedAt
        ]
        if let uid = p.userID { d["userID"] = uid }
        return d
    }

    func matchToDict(_ m: TournamentMatch) -> [String: Any] {
        var d: [String: Any] = [
            "id": m.id, "court": m.court,
            "teamA": m.teamA, "teamB": m.teamB
        ]
        if let w = m.winnerTeam { d["winnerTeam"] = w.rawValue }
        return d
    }

    func sessionToDict(_ s: TournamentSession) -> [String: Any] {
        [
            "id": s.id,
            "squadID": s.squadID,
            "createdBy": s.createdBy,
            "createdAt": s.createdAt,
            "status": s.status.rawValue,
            "courts": s.courts,
            "roundNumber": s.roundNumber,
            "matchCounter": s.matchCounter,
            "players": s.players.map(playerToDict),
            "currentRound": s.currentRound.map(matchToDict),
            "partnerships": s.partnerships
        ]
    }

    #if canImport(FirebaseFirestore)
    func playerFrom(_ d: [String: Any]) -> TournamentPlayer? {
        guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
        return TournamentPlayer(
            id: id, name: name,
            userID: d["userID"] as? String,
            played: d["played"] as? Int ?? 0,
            wins: d["wins"] as? Int ?? 0,
            losses: d["losses"] as? Int ?? 0,
            lastPlayedAt: d["lastPlayedAt"] as? Int ?? 0
        )
    }

    func matchFrom(_ d: [String: Any]) -> TournamentMatch? {
        guard let id = d["id"] as? String,
              let court = d["court"] as? Int,
              let teamA = d["teamA"] as? [String],
              let teamB = d["teamB"] as? [String] else { return nil }
        return TournamentMatch(
            id: id, court: court, teamA: teamA, teamB: teamB,
            winnerTeam: (d["winnerTeam"] as? String).flatMap(WinnerTeam.init)
        )
    }

    func sessionFrom(_ d: [String: Any], sessionID: String) -> TournamentSession? {
        guard let squadID = d["squadID"] as? String,
              let createdBy = d["createdBy"] as? String,
              let statusRaw = d["status"] as? String,
              let status = TournamentStatus(rawValue: statusRaw) else { return nil }
        return TournamentSession(
            id: sessionID,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? .now,
            status: status,
            courts: d["courts"] as? Int ?? 1,
            players: (d["players"] as? [[String: Any]] ?? []).compactMap(playerFrom),
            currentRound: (d["currentRound"] as? [[String: Any]] ?? []).compactMap(matchFrom),
            roundNumber: d["roundNumber"] as? Int ?? 0,
            matchCounter: d["matchCounter"] as? Int ?? 0,
            completedMatches: [],
            partnerships: d["partnerships"] as? [String: [String: Int]] ?? [:]
        )
    }
    #endif
}
