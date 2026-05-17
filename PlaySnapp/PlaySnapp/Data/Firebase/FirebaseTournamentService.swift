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

    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer],
                  mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Tournament, TournamentSession) {
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
            participantUserIDs: players.compactMap(\.userID),
            endedAt: nil,
            scheduledStart: nil,
            location: nil,
            mode: mode,
            fixedTeams: fixedTeams
        )
        session.currentRound = mode == .fixedTeams
            ? TournamentRotationEngine.generateFixedTeamRound(session: session)
            : TournamentRotationEngine.fillAllCourts(session: session)

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

    nonisolated func observeSession(squadID: String, tournamentID: String, sessionID: String) -> AsyncStream<TournamentSession> {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let path = FirestorePaths.tournamentSession(squadID, tournamentID, sessionID)
        return AsyncStream { continuation in
            let listener = db.document(path).addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                guard let statusRaw = data["status"] as? String,
                      let status = TournamentStatus(rawValue: statusRaw) else { return }

                func parsePlayer(_ d: [String: Any]) -> TournamentPlayer? {
                    guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
                    return TournamentPlayer(
                        id: id, name: name, userID: d["userID"] as? String,
                        played: d["played"] as? Int ?? 0,
                        wins: d["wins"] as? Int ?? 0,
                        losses: d["losses"] as? Int ?? 0,
                        lastPlayedAt: d["lastPlayedAt"] as? Int ?? 0,
                        isActive: d["isActive"] as? Bool ?? true
                    )
                }

                func parseMatch(_ d: [String: Any]) -> TournamentMatch? {
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

                func parseFixedTeam(_ d: [String: Any]) -> FixedTeam? {
                    guard let id = d["id"] as? String,
                          let name = d["name"] as? String,
                          let playerIDs = d["playerIDs"] as? [String] else { return nil }
                    return FixedTeam(id: id, name: name, playerIDs: playerIDs)
                }

                let sessionMode = (data["mode"] as? String).flatMap(SessionMode.init) ?? .rotation
                let sessionFixedTeams = (data["fixedTeams"] as? [[String: Any]] ?? []).compactMap(parseFixedTeam)

                let session = TournamentSession(
                    id: sessionID, tournamentID: tournamentID, squadID: squadID,
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

    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.currentRound = session.mode == .fixedTeams
            ? TournamentRotationEngine.generateFixedTeamRound(session: updated)
            : TournamentRotationEngine.fillAllCourts(session: updated)
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

        // Re-fetch latest player states to capture bench changes from other devices.
        var updated = session
        if let freshData = try? await firestore
            .document(FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id))
            .getDocument().data(),
           let freshPlayers = (freshData["players"] as? [[String: Any]])?.compactMap({ playerFrom($0) }),
           !freshPlayers.isEmpty {
            updated.players = freshPlayers
        }

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
        let nextMatch = updated.mode == .fixedTeams
            ? TournamentRotationEngine.nextFixedTeamMatch(court: match.court, session: updated)
            : TournamentRotationEngine.generateMatchForCourt(court: match.court, session: updated)
        if let next = nextMatch {
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

    // MARK: - Participant self-actions

    func setSelfBench(playerID: String, isActive: Bool, for session: TournamentSession) async throws -> TournamentSession {
        var players = session.players
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return session }
        players[idx].isActive = isActive
        return try await updatePlayers(players, for: session)
    }

    // MARK: - Fixed teams

    func setFixedTeams(_ teams: [FixedTeam], for session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id))
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

    func scheduleSession(for tournament: Tournament, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        let sessionID = UUID().uuidString
        let session = TournamentSession(
            id: sessionID, tournamentID: tournament.id, squadID: tournament.squadID,
            createdBy: tournament.createdBy, createdAt: .now, title: title,
            status: .scheduled, courts: courts, players: [], currentRound: [],
            roundNumber: 0, matchCounter: 0, completedMatches: [], partnerships: [:],
            participantUserIDs: [], endedAt: nil, scheduledStart: scheduledStart, location: location,
            mode: .rotation, fixedTeams: []
        )
        var dict = sessionToDict(session)
        dict["scheduledStart"] = scheduledStart
        if let loc = location { dict["location"] = loc }
        try await firestore
            .document(FirestorePaths.tournamentSession(tournament.squadID, tournament.id, sessionID))
            .setData(dict)
        return session
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func cancelScheduledSession(_ session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        try await firestore
            .document(FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id))
            .updateData(["status": TournamentStatus.cancelled.rawValue])
        var updated = session; updated.status = .cancelled; return updated
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func startScheduledSession(_ session: TournamentSession, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        var updated = session
        updated.status = .active
        updated.courts = courts
        updated.players = players
        updated.participantUserIDs = players.compactMap(\.userID)
        updated.currentRound = updated.mode == .fixedTeams
            ? TournamentRotationEngine.generateFixedTeamRound(session: updated)
            : TournamentRotationEngine.fillAllCourts(session: updated)

        let sessionRef = firestore.document(
            FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id)
        )
        try await sessionRef.updateData([
            "status": TournamentStatus.active.rawValue,
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

    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: TournamentSession) async throws {
        #if canImport(FirebaseFirestore)
        let ref = firestore.document(
            FirestorePaths.registration(session.squadID, session.tournamentID, session.id, userID)
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

    func checkInPlayer(userID: String, name: String, in session: TournamentSession) async throws -> TournamentSession {
        #if canImport(FirebaseFirestore)
        let regRef = firestore.document(
            FirestorePaths.registration(session.squadID, session.tournamentID, session.id, userID)
        )

        if session.status == .active {
            // Mid-session: stamp check-in + append to roster in one batch
            let newPlayer = TournamentPlayer(id: UUID().uuidString, name: name, userID: userID,
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
                FirestorePaths.tournamentSession(session.squadID, session.tournamentID, session.id)
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

    nonisolated func observeRegistrations(for session: TournamentSession) -> AsyncStream<[Registration]> {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let path = FirestorePaths.registrations(session.squadID, session.tournamentID, session.id)
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

    func fetchNextScheduledSession(squadID: String) async throws -> TournamentSession? {
        #if canImport(FirebaseFirestore)
        let now = Date.now
        let tournamentsSnap = try await firestore
            .collection(FirestorePaths.tournaments(squadID))
            .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
            .getDocuments()
        for tDoc in tournamentsSnap.documents {
            let tournamentID = tDoc.documentID
            let sessionsSnap = try await firestore
                .collection(FirestorePaths.tournamentSessions(squadID, tournamentID))
                .whereField("status", isEqualTo: TournamentStatus.scheduled.rawValue)
                .order(by: "scheduledStart")
                .limit(to: 1)
                .getDocuments()
            if let sDoc = sessionsSnap.documents.first,
               let session = sessionFrom(sDoc.data(), sessionID: sDoc.documentID,
                                         tournamentID: tournamentID, squadID: squadID),
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

private extension FirebaseTournamentService {

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
            "participantUserIDs": s.participantUserIDs,
            "mode": s.mode.rawValue,
            "fixedTeams": s.fixedTeams.map(fixedTeamToDict)
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
        let mode = (d["mode"] as? String).flatMap(SessionMode.init) ?? .rotation
        let fixedTeams = (d["fixedTeams"] as? [[String: Any]] ?? []).compactMap(fixedTeamFrom)
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
            endedAt: (d["endedAt"] as? Timestamp)?.dateValue(),
            scheduledStart: (d["scheduledStart"] as? Timestamp)?.dateValue(),
            location: d["location"] as? String,
            mode: mode,
            fixedTeams: fixedTeams
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
