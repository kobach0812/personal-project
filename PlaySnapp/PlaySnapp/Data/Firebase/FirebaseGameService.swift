import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseGameService: GameServicing {

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    // MARK: - Game lifecycle

    func createGame(squadID: String, createdBy: String, title: String, players: [GamePlayer]) async throws -> Game {
        #if canImport(FirebaseFirestore)
        let gameID = UUID().uuidString
        let game = Game(
            id: gameID, squadID: squadID, createdBy: createdBy,
            createdAt: .now, title: title, status: .active,
            players: players, activeDayID: nil, sessions: []
        )
        try await firestore
            .document(FirestorePaths.game(squadID, gameID))
            .setData(gameToDict(game))
        return game
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchGames(squadID: String) async throws -> [Game] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.games(squadID))
            .getDocuments()
        let list = snapshot.documents.compactMap { gameFrom($0.data(), gameID: $0.documentID) }
        return list.sorted { lhs, rhs in
            if (lhs.status == .active) != (rhs.status == .active) { return lhs.status == .active }
            return lhs.createdAt > rhs.createdAt
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func endGame(_ game: Game) async throws {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.game(game.squadID, game.id))
            .updateData(["status": GameStatus.finished.rawValue])
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Roster management

    func setGameRoster(_ players: [GamePlayer], for game: Game) async throws -> Game {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.game(game.squadID, game.id))
            .updateData(["players": players.map(playerToDict)])
        var t = game
        t.players = players
        return t
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func removePlayer(playerID: String, from game: Game) async throws -> Game {
        #if canImport(FirebaseFirestore)
        var t = game
        t.players.removeAll { $0.id == playerID }
        try await firestore
            .document(FirestorePaths.game(game.squadID, game.id))
            .updateData(["players": t.players.map(playerToDict)])
        return t
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func addPlayers(_ newPlayers: [GamePlayer], to game: Game) async throws -> Game {
        #if canImport(FirebaseFirestore)
        var t = game
        let existingUserIDs = Set(t.players.compactMap(\.userID))
        let existingNames   = Set(t.players.filter { $0.userID == nil }.map(\.name))
        for p in newPlayers {
            if let uid = p.userID { if !existingUserIDs.contains(uid) { t.players.append(p) } }
            else                  { if !existingNames.contains(p.name)  { t.players.append(p) } }
        }
        try await firestore
            .document(FirestorePaths.game(game.squadID, game.id))
            .updateData(["players": t.players.map(playerToDict)])
        return t
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Day / session lifecycle

    func startDay(for game: Game, courts: Int, players: [GamePlayer],
                  mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Game, GameSession) {
        #if canImport(FirebaseFirestore)
        let sessionID = UUID().uuidString

        // Count existing sessions to generate "Day N" label
        let existing = try? await firestore
            .collection(FirestorePaths.gameSessions(game.squadID, game.id))
            .getDocuments()
        let dayNumber = (existing?.documents.count ?? 0) + 1

        var session = GameSession(
            id: sessionID,
            gameID: game.id,
            squadID: game.squadID,
            createdBy: game.createdBy,
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

        let batch = firestore.batch()

        let sessionRef = firestore.document(
            FirestorePaths.gameSession(game.squadID, game.id, sessionID)
        )
        batch.setData(sessionToDict(session), forDocument: sessionRef)

        let gameRef = firestore.document(
            FirestorePaths.game(game.squadID, game.id)
        )
        batch.updateData(["activeDayID": sessionID], forDocument: gameRef)

        try await batch.commit()

        var updatedGame = game
        updatedGame.activeDayID = sessionID
        return (updatedGame, session)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func endDay(_ session: GameSession, for game: Game) async throws -> Game {
        #if canImport(FirebaseFirestore)
        let mergedPlayers = mergeStats(into: game.players, from: session.players)

        let batch = firestore.batch()

        let sessionRef = firestore.document(
            FirestorePaths.gameSession(game.squadID, game.id, session.id)
        )
        batch.updateData([
            "status": GameStatus.finished.rawValue,
            "endedAt": Date.now
        ], forDocument: sessionRef)

        let gameRef = firestore.document(
            FirestorePaths.game(game.squadID, game.id)
        )
        batch.updateData([
            "activeDayID": FieldValue.delete(),
            "players": mergedPlayers.map(playerToDict)
        ], forDocument: gameRef)

        try await batch.commit()

        var updated = game
        updated.activeDayID = nil
        updated.players = mergedPlayers
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchSessions(for game: Game) async throws -> [GameSession] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.gameSessions(game.squadID, game.id))
            .getDocuments()
        return snapshot.documents
            .compactMap { sessionFrom($0.data(), sessionID: $0.documentID,
                                     gameID: game.id, squadID: game.squadID) }
            .sorted { $0.createdAt < $1.createdAt }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchMatches(for session: GameSession) async throws -> [GameMatch] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.sessionMatches(session.squadID, session.gameID, session.id))
            .order(by: "completedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { matchFrom($0.data()) }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - In-session operations

    nonisolated func observeSession(squadID: String, gameID: String, sessionID: String) -> AsyncStream<GameSession> {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let path = FirestorePaths.gameSession(squadID, gameID, sessionID)
        return AsyncStream { continuation in
            let listener = db.document(path).addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                guard let statusRaw = data["status"] as? String,
                      let status = GameStatus(rawValue: statusRaw) else { return }

                func parsePlayer(_ d: [String: Any]) -> GamePlayer? {
                    guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
                    return GamePlayer(
                        id: id, name: name, userID: d["userID"] as? String,
                        played: d["played"] as? Int ?? 0,
                        wins: d["wins"] as? Int ?? 0,
                        losses: d["losses"] as? Int ?? 0,
                        lastPlayedAt: d["lastPlayedAt"] as? Int ?? 0,
                        isActive: d["isActive"] as? Bool ?? true
                    )
                }

                func parseMatch(_ d: [String: Any]) -> GameMatch? {
                    guard let id = d["id"] as? String,
                          let court = d["court"] as? Int,
                          let teamA = d["teamA"] as? [String],
                          let teamB = d["teamB"] as? [String] else { return nil }
                    return GameMatch(
                        id: id, court: court, teamA: teamA, teamB: teamB,
                        winnerTeam: (d["winnerTeam"] as? String).flatMap(WinnerTeam.init),
                        teamAScore: d["teamAScore"] as? Int,
                        teamBScore: d["teamBScore"] as? Int,
                        completedAt: (d["completedAt"] as? Timestamp)?.dateValue()
                    )
                }

                func parseFixedTeam(_ d: [String: Any]) -> FixedTeam? {
                    guard let id = d["id"] as? String,
                          let name = d["name"] as? String,
                          let playerIDs = d["playerIDs"] as? [String] else { return nil }
                    return FixedTeam(id: id, name: name, playerIDs: playerIDs)
                }

                let sessionMode = (data["mode"] as? String).flatMap(SessionMode.init) ?? .rotation
                let sessionFixedTeams = (data["fixedTeams"] as? [[String: Any]] ?? []).compactMap(parseFixedTeam)

                let session = GameSession(
                    id: sessionID, gameID: gameID, squadID: squadID,
                    createdBy: data["createdBy"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now,
                    title: data["title"] as? String ?? "",
                    status: status,
                    courts: data["courts"] as? Int ?? 1,
                    players: (data["players"] as? [[String: Any]] ?? []).compactMap(parsePlayer),
                    currentRound: (data["currentRound"] as? [[String: Any]] ?? []).compactMap(parseMatch),
                    roundNumber: data["roundNumber"] as? Int ?? 0,
                    matchCounter: data["matchCounter"] as? Int ?? 0,
                    completedMatches: [],
                    partnerships: data["partnerships"] as? [String: [String: Int]] ?? [:],
                    participantUserIDs: data["participantUserIDs"] as? [String] ?? [],
                    endedAt: (data["endedAt"] as? Timestamp)?.dateValue(),
                    scheduledStart: (data["scheduledStart"] as? Timestamp)?.dateValue(),
                    location: data["location"] as? String,
                    mode: sessionMode,
                    fixedTeams: sessionFixedTeams
                )
                continuation.yield(session)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
        #else
        return AsyncStream { $0.finish() }
        #endif
    }

    func generateNextRound(for session: GameSession) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.currentRound = session.mode == .fixedTeams
            ? GameRotationEngine.generateFixedTeamRound(session: updated)
            : GameRotationEngine.fillAllCourts(session: updated)
        try await firestore
            .document(FirestorePaths.gameSession(session.squadID, session.gameID, session.id))
            .updateData(["currentRound": updated.currentRound.map(matchToDict)])
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func recordResult(for session: GameSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        guard let match = session.currentRound.first(where: { $0.id == matchID }) else { return session }

        // Re-fetch latest player states to capture bench changes from other devices.
        var updated = session
        if let freshData = try? await firestore
            .document(FirestorePaths.gameSession(session.squadID, session.gameID, session.id))
            .getDocument().data(),
           let freshPlayers = (freshData["players"] as? [[String: Any]])?.compactMap({ playerFrom($0) }),
           !freshPlayers.isEmpty {
            updated.players = freshPlayers
        }

        updated.matchCounter += 1
        updated.players = GameRotationEngine.applyResult(
            players: updated.players, match: match,
            winner: winner, matchCounter: updated.matchCounter
        )
        updated.partnerships = GameRotationEngine.updatePartnerships(updated.partnerships, match: match)

        var archived = match
        archived.winnerTeam = winner
        archived.teamAScore = scoreA
        archived.teamBScore = scoreB
        archived.completedAt = .now
        updated.completedMatches.insert(archived, at: 0)

        updated.currentRound.removeAll { $0.id == matchID }
        let nextMatch = updated.mode == .fixedTeams
            ? GameRotationEngine.nextFixedTeamMatch(court: match.court, session: updated)
            : GameRotationEngine.generateMatchForCourt(court: match.court, session: updated)
        if let next = nextMatch {
            updated.currentRound.append(next)
        }

        let winnerIDs = winner == .teamA ? match.teamA : match.teamB
        let loserIDs  = winner == .teamA ? match.teamB : match.teamA

        let batch = firestore.batch()

        let sessionRef = firestore.document(
            FirestorePaths.gameSession(session.squadID, session.gameID, session.id)
        )
        batch.updateData([
            "currentRound": updated.currentRound.map(matchToDict),
            "players": updated.players.map(playerToDict),
            "partnerships": updated.partnerships,
            "matchCounter": updated.matchCounter
        ], forDocument: sessionRef)

        let matchRef = firestore.document(
            FirestorePaths.sessionMatch(session.squadID, session.gameID, session.id, archived.id)
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

    func updatePlayers(_ players: [GamePlayer], for session: GameSession) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.gameSession(session.squadID, session.gameID, session.id))
            .updateData(["players": players.map(playerToDict)])
        var updated = session
        updated.players = players
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Participant self-actions

    func setSelfBench(playerID: String, isActive: Bool, for session: GameSession) async throws -> GameSession {
        var players = session.players
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return session }
        players[idx].isActive = isActive
        return try await updatePlayers(players, for: session)
    }

    // MARK: - Fixed teams

    func setFixedTeams(_ teams: [FixedTeam], for session: GameSession) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.gameSession(session.squadID, session.gameID, session.id))
            .updateData([
                "mode": SessionMode.fixedTeams.rawValue,
                "fixedTeams": teams.map(fixedTeamToDict)
            ])
        var updated = session
        updated.mode = .fixedTeams
        updated.fixedTeams = teams
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Scheduled day lifecycle

    func scheduleSession(for game: Game, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        let sessionID = UUID().uuidString
        let session = GameSession(
            id: sessionID, gameID: game.id, squadID: game.squadID,
            createdBy: game.createdBy, createdAt: .now, title: title,
            status: .scheduled, courts: courts, players: [], currentRound: [],
            roundNumber: 0, matchCounter: 0, completedMatches: [], partnerships: [:],
            participantUserIDs: [], endedAt: nil, scheduledStart: scheduledStart, location: location,
            mode: .rotation, fixedTeams: []
        )
        var dict = sessionToDict(session)
        dict["scheduledStart"] = scheduledStart
        if let loc = location { dict["location"] = loc }
        try await firestore
            .document(FirestorePaths.gameSession(game.squadID, game.id, sessionID))
            .setData(dict)
        return session
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func cancelScheduledSession(_ session: GameSession) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.gameSession(session.squadID, session.gameID, session.id))
            .updateData(["status": GameStatus.cancelled.rawValue])
        var updated = session; updated.status = .cancelled; return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func startScheduledSession(_ session: GameSession, courts: Int, players: [GamePlayer]) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.status = .active
        updated.courts = courts
        updated.players = players
        updated.participantUserIDs = players.compactMap(\.userID)
        updated.currentRound = updated.mode == .fixedTeams
            ? GameRotationEngine.generateFixedTeamRound(session: updated)
            : GameRotationEngine.fillAllCourts(session: updated)

        let sessionRef = firestore.document(
            FirestorePaths.gameSession(session.squadID, session.gameID, session.id)
        )
        try await sessionRef.updateData([
            "status": GameStatus.active.rawValue,
            "courts": courts,
            "players": players.map(playerToDict),
            "currentRound": updated.currentRound.map(matchToDict),
            "participantUserIDs": updated.participantUserIDs
        ])
        return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - RSVP

    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: GameSession) async throws {
        #if canImport(FirebaseFirestore)
        let ref = firestore.document(
            FirestorePaths.registration(session.squadID, session.gameID, session.id, userID)
        )
        try await ref.setData([
            "userID": userID, "name": name,
            "status": status.rawValue,
            "registeredAt": Date.now,
            "addedToRoster": false
        ], merge: true)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Check-in

    func checkInPlayer(userID: String, name: String, in session: GameSession) async throws -> GameSession {
        #if canImport(FirebaseFirestore)
        let regRef = firestore.document(
            FirestorePaths.registration(session.squadID, session.gameID, session.id, userID)
        )

        if session.status == .active {
            // Mid-session: stamp check-in + append to roster in one batch
            let newPlayer = GamePlayer(id: UUID().uuidString, name: name, userID: userID,
                                             played: 0, wins: 0, losses: 0, lastPlayedAt: 0, isActive: true)
            var updated = session
            updated.players.append(newPlayer)
            updated.participantUserIDs.append(userID)

            let batch = firestore.batch()
            batch.setData([
                "userID": userID, "name": name, "status": RegistrationStatus.yes.rawValue,
                "registeredAt": Date.now, "checkedInAt": Date.now, "addedToRoster": true
            ], forDocument: regRef, merge: true)
            let sessionRef = firestore.document(
                FirestorePaths.gameSession(session.squadID, session.gameID, session.id)
            )
            batch.updateData([
                "players": updated.players.map(playerToDict),
                "participantUserIDs": updated.participantUserIDs
            ], forDocument: sessionRef)
            try await batch.commit()
            return updated
        } else {
            // Scheduled: just stamp check-in
            try await regRef.setData([
                "userID": userID, "name": name, "status": RegistrationStatus.yes.rawValue,
                "registeredAt": Date.now, "checkedInAt": Date.now, "addedToRoster": false
            ], merge: true)
            return session
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    nonisolated func observeRegistrations(for session: GameSession) -> AsyncStream<[Registration]> {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let path = FirestorePaths.registrations(session.squadID, session.gameID, session.id)
        return AsyncStream { continuation in
            let listener = db.collection(path).addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let regs: [Registration] = docs.compactMap { doc in
                    let d = doc.data()
                    guard let userID = d["userID"] as? String,
                          let name = d["name"] as? String,
                          let statusRaw = d["status"] as? String,
                          let status = RegistrationStatus(rawValue: statusRaw)
                    else { return nil }
                    return Registration(
                        id: doc.documentID, userID: userID, name: name, status: status,
                        registeredAt: (d["registeredAt"] as? Timestamp)?.dateValue() ?? .now,
                        checkedInAt: (d["checkedInAt"] as? Timestamp)?.dateValue(),
                        addedToRoster: d["addedToRoster"] as? Bool ?? false
                    )
                }
                continuation.yield(regs)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
        #else
        return AsyncStream { $0.finish() }
        #endif
    }

    func fetchNextScheduledSession(squadID: String) async throws -> GameSession? {
        #if canImport(FirebaseFirestore)
        let now = Date.now
        let gamesSnap = try await firestore
            .collection(FirestorePaths.games(squadID))
            .whereField("status", isEqualTo: GameStatus.active.rawValue)
            .getDocuments()
        for tDoc in gamesSnap.documents {
            let gameID = tDoc.documentID
            let sessionsSnap = try await firestore
                .collection(FirestorePaths.gameSessions(squadID, gameID))
                .whereField("status", isEqualTo: GameStatus.scheduled.rawValue)
                .order(by: "scheduledStart")
                .limit(to: 1)
                .getDocuments()
            if let sDoc = sessionsSnap.documents.first,
               let session = sessionFrom(sDoc.data(), sessionID: sDoc.documentID,
                                         gameID: gameID, squadID: squadID),
               let start = session.scheduledStart, start > now {
                return session
            }
        }
        return nil
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }
}

// MARK: - Serialization

private extension FirebaseGameService {

    func fixedTeamToDict(_ t: FixedTeam) -> [String: Any] {
        ["id": t.id, "name": t.name, "playerIDs": t.playerIDs]
    }

    #if canImport(FirebaseFirestore)
    func fixedTeamFrom(_ d: [String: Any]) -> FixedTeam? {
        guard let id = d["id"] as? String,
              let name = d["name"] as? String,
              let playerIDs = d["playerIDs"] as? [String] else { return nil }
        return FixedTeam(id: id, name: name, playerIDs: playerIDs)
    }
    #endif

    func playerToDict(_ p: GamePlayer) -> [String: Any] {
        var d: [String: Any] = [
            "id": p.id, "name": p.name,
            "played": p.played, "wins": p.wins, "losses": p.losses,
            "lastPlayedAt": p.lastPlayedAt,
            "isActive": p.isActive
        ]
        if let uid = p.userID { d["userID"] = uid }
        return d
    }

    func matchToDict(_ m: GameMatch) -> [String: Any] {
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

    func sessionToDict(_ s: GameSession) -> [String: Any] {
        [
            "id": s.id,
            "gameID": s.gameID,
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
            "participantUserIDs": s.participantUserIDs,
            "mode": s.mode.rawValue,
            "fixedTeams": s.fixedTeams.map(fixedTeamToDict)
        ]
    }

    func gameToDict(_ t: Game) -> [String: Any] {
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
    func playerFrom(_ d: [String: Any]) -> GamePlayer? {
        guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
        return GamePlayer(
            id: id, name: name,
            userID: d["userID"] as? String,
            played: d["played"] as? Int ?? 0,
            wins: d["wins"] as? Int ?? 0,
            losses: d["losses"] as? Int ?? 0,
            lastPlayedAt: d["lastPlayedAt"] as? Int ?? 0,
            isActive: d["isActive"] as? Bool ?? true
        )
    }

    func matchFrom(_ d: [String: Any]) -> GameMatch? {
        guard let id = d["id"] as? String,
              let court = d["court"] as? Int,
              let teamA = d["teamA"] as? [String],
              let teamB = d["teamB"] as? [String] else { return nil }
        return GameMatch(
            id: id, court: court, teamA: teamA, teamB: teamB,
            winnerTeam: (d["winnerTeam"] as? String).flatMap(WinnerTeam.init),
            teamAScore: d["teamAScore"] as? Int,
            teamBScore: d["teamBScore"] as? Int,
            completedAt: (d["completedAt"] as? Timestamp)?.dateValue()
        )
    }

    func sessionFrom(_ d: [String: Any], sessionID: String, gameID: String, squadID: String) -> GameSession? {
        guard let statusRaw = d["status"] as? String,
              let status = GameStatus(rawValue: statusRaw) else { return nil }
        let mode = (d["mode"] as? String).flatMap(SessionMode.init) ?? .rotation
        let fixedTeams = (d["fixedTeams"] as? [[String: Any]] ?? []).compactMap(fixedTeamFrom)
        return GameSession(
            id: sessionID,
            gameID: gameID,
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
            endedAt: (d["endedAt"] as? Timestamp)?.dateValue(),
            scheduledStart: (d["scheduledStart"] as? Timestamp)?.dateValue(),
            location: d["location"] as? String,
            mode: mode,
            fixedTeams: fixedTeams
        )
    }

    func gameFrom(_ d: [String: Any], gameID: String) -> Game? {
        guard let squadID = d["squadID"] as? String,
              let createdBy = d["createdBy"] as? String,
              let statusRaw = d["status"] as? String,
              let status = GameStatus(rawValue: statusRaw) else { return nil }
        return Game(
            id: gameID,
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

    #if canImport(FirebaseFirestore)
    func registrationFrom(_ d: [String: Any], docID: String) -> Registration? {
        guard let userID = d["userID"] as? String,
              let name = d["name"] as? String,
              let statusRaw = d["status"] as? String,
              let status = RegistrationStatus(rawValue: statusRaw)
        else { return nil }
        return Registration(
            id: docID, userID: userID, name: name, status: status,
            registeredAt: (d["registeredAt"] as? Timestamp)?.dateValue() ?? .now,
            checkedInAt: (d["checkedInAt"] as? Timestamp)?.dateValue(),
            addedToRoster: d["addedToRoster"] as? Bool ?? false
        )
    }
    #endif

    func mergeStats(into base: [GamePlayer], from day: [GamePlayer]) -> [GamePlayer] {
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
