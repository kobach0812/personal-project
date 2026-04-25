import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseTournamentService: TournamentServicing {

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    // MARK: - Tournament lifecycle

    func createTournament(squadID: String, createdBy: String, title: String, players: [TournamentPlayer]) async throws -> Tournament {
        #if canImport(FirebaseFirestore)
        let tournamentID = UUID().uuidString
        let tournament = Tournament(
            id: tournamentID, squadID: squadID, createdBy: createdBy,
            createdAt: .now, title: title, status: .active,
            players: players, activeDayID: nil, sessions: []
        )
        try await firestore
            .document(FirestorePaths.tournament(squadID, tournamentID))
            .setData(tournamentToDict(tournament))
        return tournament
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchTournaments(squadID: String) async throws -> [Tournament] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.tournaments(squadID))
            .getDocuments()
        let list = snapshot.documents.compactMap { tournamentFrom($0.data(), tournamentID: $0.documentID) }
        return list.sorted { lhs, rhs in
            if (lhs.status == .active) != (rhs.status == .active) { return lhs.status == .active }
            return lhs.createdAt > rhs.createdAt
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func endTournament(_ tournament: Tournament) async throws {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournament(tournament.squadID, tournament.id))
            .updateData(["status": TournamentStatus.finished.rawValue])
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Roster management

    func setTournamentRoster(_ players: [TournamentPlayer], for tournament: Tournament) async throws -> Tournament {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournament(tournament.squadID, tournament.id))
            .updateData(["players": players.map(playerToDict)])
        var t = tournament
        t.players = players
        return t
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func addPlayers(_ newPlayers: [TournamentPlayer], to tournament: Tournament) async throws -> Tournament {
        #if canImport(FirebaseFirestore)
        var t = tournament
        let existingUserIDs = Set(t.players.compactMap(\.userID))
        let existingNames   = Set(t.players.filter { $0.userID == nil }.map(\.name))
        for p in newPlayers {
            if let uid = p.userID { if !existingUserIDs.contains(uid) { t.players.append(p) } }
            else                  { if !existingNames.contains(p.name)  { t.players.append(p) } }
        }
        try await firestore
            .document(FirestorePaths.tournament(tournament.squadID, tournament.id))
            .updateData(["players": t.players.map(playerToDict)])
        return t
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Day / session lifecycle

    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer]) async throws -> (Tournament, TournamentSession) {
        #if canImport(FirebaseFirestore)
        let sessionID = UUID().uuidString

        // Count existing sessions to generate "Day N" label
        let existing = try? await firestore
            .collection(FirestorePaths.tournamentSessions(tournament.squadID, tournament.id))
            .getDocuments()
        let dayNumber = (existing?.documents.count ?? 0) + 1

        var session = TournamentSession(
            id: sessionID,
            tournamentID: tournament.id,
            squadID: tournament.squadID,
            createdBy: tournament.createdBy,
            createdAt: .now,
            title: "Day \(dayNumber)",
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

        let batch = firestore.batch()

        let sessionRef = firestore.document(
            FirestorePaths.tournamentSession(tournament.squadID, tournament.id, sessionID)
        )
        batch.setData(sessionToDict(session), forDocument: sessionRef)

        let tournamentRef = firestore.document(
            FirestorePaths.tournament(tournament.squadID, tournament.id)
        )
        batch.updateData(["activeDayID": sessionID], forDocument: tournamentRef)

        try await batch.commit()

        var updatedTournament = tournament
        updatedTournament.activeDayID = sessionID
        return (updatedTournament, session)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func endDay(_ session: TournamentSession, for tournament: Tournament) async throws -> Tournament {
        #if canImport(FirebaseFirestore)
        let mergedPlayers = mergeStats(into: tournament.players, from: session.players)

        let batch = firestore.batch()

        let sessionRef = firestore.document(
            FirestorePaths.tournamentSession(tournament.squadID, tournament.id, session.id)
        )
        batch.updateData([
            "status": TournamentStatus.finished.rawValue,
            "endedAt": Date.now
        ], forDocument: sessionRef)

        let tournamentRef = firestore.document(
            FirestorePaths.tournament(tournament.squadID, tournament.id)
        )
        batch.updateData([
            "activeDayID": FieldValue.delete(),
            "players": mergedPlayers.map(playerToDict)
        ], forDocument: tournamentRef)

        try await batch.commit()

        var updated = tournament
        updated.activeDayID = nil
        updated.players = mergedPlayers
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchSessions(for tournament: Tournament) async throws -> [TournamentSession] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.tournamentSessions(tournament.squadID, tournament.id))
            .getDocuments()
        return snapshot.documents
            .compactMap { sessionFrom($0.data(), sessionID: $0.documentID,
                                     tournamentID: tournament.id, squadID: tournament.squadID) }
            .sorted { $0.createdAt < $1.createdAt }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchMatches(for session: TournamentSession) async throws -> [TournamentMatch] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.sessionMatches(session.squadID, session.tournamentID, session.id))
            .order(by: "completedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { matchFrom($0.data()) }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - In-session operations

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.currentRound = TournamentRotationEngine.fillAllCourts(session: updated)
        try await firestore
            .document(FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id))
            .updateData(["currentRound": updated.currentRound.map(matchToDict)])
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
            players: updated.players, match: match,
            winner: winner, matchCounter: updated.matchCounter
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

        let sessionRef = firestore.document(
            FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id)
        )
        batch.updateData([
            "currentRound": updated.currentRound.map(matchToDict),
            "players": updated.players.map(playerToDict),
            "partnerships": updated.partnerships,
            "matchCounter": updated.matchCounter
        ], forDocument: sessionRef)

        let matchRef = firestore.document(
            FirestorePaths.sessionMatch(session.squadID, session.tournamentID, session.id, archived.id)
        )
        batch.setData(matchToDict(archived), forDocument: matchRef)

        for id in winnerIDs + loserIDs {
            guard let player = updated.players.first(where: { $0.id == id }),
                  let userID = player.userID else { continue }
            let ref = firestore.document(FirestorePaths.leaderboardEntry(session.squadID, userID))
            let isWinner = winnerIDs.contains(id)
            batch.setData([
                "name": player.name,
                "totalPlayed": FieldValue.increment(Int64(1)),
                "totalWins":   FieldValue.increment(Int64(isWinner ? 1 : 0)),
                "totalLosses": FieldValue.increment(Int64(isWinner ? 0 : 1))
            ], forDocument: ref, merge: true)
        }

        try await batch.commit()
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func updatePlayers(_ players: [TournamentPlayer], for session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id))
            .updateData(["players": players.map(playerToDict)])
        var updated = session
        updated.players = players
        return updated
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
            "lastPlayedAt": p.lastPlayedAt,
            "isActive": p.isActive
        ]
        if let uid = p.userID { d["userID"] = uid }
        return d
    }

    func matchToDict(_ m: TournamentMatch) -> [String: Any] {
        var d: [String: Any] = [
            "id": m.id, "court": m.court,
            "teamA": m.teamA, "teamB": m.teamB
        ]
        if let w = m.winnerTeam  { d["winnerTeam"] = w.rawValue }
        if let a = m.teamAScore  { d["teamAScore"] = a }
        if let b = m.teamBScore  { d["teamBScore"] = b }
        if let t = m.completedAt { d["completedAt"] = t }
        return d
    }

    func sessionToDict(_ s: TournamentSession) -> [String: Any] {
        [
            "id": s.id,
            "tournamentID": s.tournamentID,
            "squadID": s.squadID,
            "createdBy": s.createdBy,
            "createdAt": s.createdAt,
            "title": s.title,
            "status": s.status.rawValue,
            "courts": s.courts,
            "roundNumber": s.roundNumber,
            "matchCounter": s.matchCounter,
            "players": s.players.map(playerToDict),
            "currentRound": s.currentRound.map(matchToDict),
            "partnerships": s.partnerships,
            "participantUserIDs": s.participantUserIDs
        ]
    }

    func tournamentToDict(_ t: Tournament) -> [String: Any] {
        var d: [String: Any] = [
            "id": t.id,
            "squadID": t.squadID,
            "createdBy": t.createdBy,
            "createdAt": t.createdAt,
            "title": t.title,
            "status": t.status.rawValue,
            "players": t.players.map(playerToDict)
        ]
        if let dayID = t.activeDayID { d["activeDayID"] = dayID }
        return d
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
            lastPlayedAt: d["lastPlayedAt"] as? Int ?? 0,
            isActive: d["isActive"] as? Bool ?? true
        )
    }

    func matchFrom(_ d: [String: Any]) -> TournamentMatch? {
        guard let id = d["id"] as? String,
              let court = d["court"] as? Int,
              let teamA = d["teamA"] as? [String],
              let teamB = d["teamB"] as? [String] else { return nil }
        return TournamentMatch(
            id: id, court: court, teamA: teamA, teamB: teamB,
            winnerTeam: (d["winnerTeam"] as? String).flatMap(WinnerTeam.init),
            teamAScore: d["teamAScore"] as? Int,
            teamBScore: d["teamBScore"] as? Int,
            completedAt: (d["completedAt"] as? Timestamp)?.dateValue()
        )
    }

    func sessionFrom(_ d: [String: Any], sessionID: String, tournamentID: String, squadID: String) -> TournamentSession? {
        guard let statusRaw = d["status"] as? String,
              let status = TournamentStatus(rawValue: statusRaw) else { return nil }
        return TournamentSession(
            id: sessionID,
            tournamentID: tournamentID,
            squadID: squadID,
            createdBy: d["createdBy"] as? String ?? "",
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? .now,
            title: d["title"] as? String ?? "",
            status: status,
            courts: d["courts"] as? Int ?? 1,
            players: (d["players"] as? [[String: Any]] ?? []).compactMap(playerFrom),
            currentRound: (d["currentRound"] as? [[String: Any]] ?? []).compactMap(matchFrom),
            roundNumber: d["roundNumber"] as? Int ?? 0,
            matchCounter: d["matchCounter"] as? Int ?? 0,
            completedMatches: [],
            partnerships: d["partnerships"] as? [String: [String: Int]] ?? [:],
            participantUserIDs: d["participantUserIDs"] as? [String] ?? [],
            endedAt: (d["endedAt"] as? Timestamp)?.dateValue()
        )
    }

    func tournamentFrom(_ d: [String: Any], tournamentID: String) -> Tournament? {
        guard let squadID = d["squadID"] as? String,
              let createdBy = d["createdBy"] as? String,
              let statusRaw = d["status"] as? String,
              let status = TournamentStatus(rawValue: statusRaw) else { return nil }
        return Tournament(
            id: tournamentID,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? .now,
            title: d["title"] as? String ?? "",
            status: status,
            players: (d["players"] as? [[String: Any]] ?? []).compactMap(playerFrom),
            activeDayID: d["activeDayID"] as? String,
            sessions: []
        )
    }
    #endif

    func mergeStats(into base: [TournamentPlayer], from day: [TournamentPlayer]) -> [TournamentPlayer] {
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
