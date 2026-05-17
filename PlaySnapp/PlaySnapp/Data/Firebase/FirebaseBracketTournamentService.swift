import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseBracketTournamentService: BracketTournamentServicing {

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    // MARK: - Lifecycle

    func createBracket(
        in tournamentID: String,
        squadID: String,
        createdBy: String,
        title: String,
        groups: [BracketGroup]
    ) async throws -> BracketTournament {
        #if canImport(FirebaseFirestore)
        let seededGroups = groups.map { g -> BracketGroup in
            var copy = g
            if copy.matches.isEmpty {
                copy.matches = BracketEngine.generateGroupMatches(teams: copy.teams)
            }
            return copy
        }
        let bracket = BracketTournament(
            id: UUID().uuidString,
            parentTournamentID: tournamentID,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: .now,
            title: title,
            status: .groupStage,
            groups: seededGroups,
            knockoutBestOf: 0,
            knockoutMatches: []
        )
        try await firestore
            .document(FirestorePaths.bracket(squadID, tournamentID, bracket.id))
            .setData(bracketToDict(bracket))
        return bracket
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchBrackets(in tournamentID: String, squadID: String) async throws -> [BracketTournament] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore
            .collection(FirestorePaths.brackets(squadID, tournamentID))
            .getDocuments()
        return snapshot.documents
            .compactMap { bracketFrom($0.data(), bracketID: $0.documentID) }
            .sorted { $0.createdAt > $1.createdAt }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Group stage

    func recordGroupMatchResult(
        bracketID: String,
        groupID: String,
        matchID: String,
        scoreA: Int,
        scoreB: Int,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament {
        #if canImport(FirebaseFirestore)
        var bracket = try await loadBracket(bracketID: bracketID, squadID: squadID, tournamentID: tournamentID)
        guard let gIdx = bracket.groups.firstIndex(where: { $0.id == groupID }),
              let mIdx = bracket.groups[gIdx].matches.firstIndex(where: { $0.id == matchID })
        else { throw BracketTournamentServiceError.bracketNotFound }

        let match = bracket.groups[gIdx].matches[mIdx]
        let winnerID: String? = scoreA == scoreB ? nil
            : (scoreA > scoreB ? match.teamAID : match.teamBID)

        bracket.groups[gIdx].matches[mIdx].scoreA = scoreA
        bracket.groups[gIdx].matches[mIdx].scoreB = scoreB
        bracket.groups[gIdx].matches[mIdx].winnerTeamID = winnerID
        bracket.groups[gIdx].matches[mIdx].completedAt = .now

        try await firestore
            .document(FirestorePaths.bracket(squadID, tournamentID, bracketID))
            .updateData(["groups": bracket.groups.map(groupToDict)])
        return bracket
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    // MARK: - Knockout

    func configureKnockout(
        bracketID: String,
        advanceCounts: [String: Int],
        bestOf: Int,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament {
        #if canImport(FirebaseFirestore)
        var bracket = try await loadBracket(bracketID: bracketID, squadID: squadID, tournamentID: tournamentID)

        var advancing: [String] = []
        for i in bracket.groups.indices {
            let count = advanceCounts[bracket.groups[i].id] ?? 0
            bracket.groups[i].advanceCount = count
            let sorted = BracketEngine.standings(for: bracket.groups[i])
            advancing.append(contentsOf: sorted.prefix(count))
        }

        guard let startingRound = BracketEngine.startingRound(for: advancing.count) else {
            throw BracketTournamentServiceError.unsupportedTeamCount
        }

        bracket.knockoutBestOf = bestOf
        bracket.knockoutMatches = BracketEngine.pairInitialMatches(teamIDs: advancing, round: startingRound)
        bracket.status = .knockout
        BracketEngine.advanceBracketIfReady(&bracket)

        try await firestore
            .document(FirestorePaths.bracket(squadID, tournamentID, bracketID))
            .updateData([
                "groups": bracket.groups.map(groupToDict),
                "knockoutBestOf": bracket.knockoutBestOf,
                "knockoutMatches": bracket.knockoutMatches.map(knockoutMatchToDict),
                "status": bracket.status.rawValue
            ])
        return bracket
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func recordKnockoutSet(
        bracketID: String,
        matchID: String,
        set: SetScore,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament {
        #if canImport(FirebaseFirestore)
        var bracket = try await loadBracket(bracketID: bracketID, squadID: squadID, tournamentID: tournamentID)
        guard bracket.knockoutBestOf > 0 else { throw BracketTournamentServiceError.knockoutNotConfigured }
        guard let mIdx = bracket.knockoutMatches.firstIndex(where: { $0.id == matchID })
        else { throw BracketTournamentServiceError.bracketNotFound }

        bracket.knockoutMatches[mIdx] = BracketEngine.applySet(
            bracket.knockoutMatches[mIdx],
            set: set,
            bestOf: bracket.knockoutBestOf
        )
        BracketEngine.advanceBracketIfReady(&bracket)

        try await firestore
            .document(FirestorePaths.bracket(squadID, tournamentID, bracketID))
            .updateData([
                "knockoutMatches": bracket.knockoutMatches.map(knockoutMatchToDict),
                "status": bracket.status.rawValue
            ])
        return bracket
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    nonisolated func observeBracket(bracketID: String, squadID: String, tournamentID: String) -> AsyncStream<BracketTournament> {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let path = FirestorePaths.bracket(squadID, tournamentID, bracketID)
        return AsyncStream { continuation in
            let listener = db.document(path).addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                if let bracket = FirebaseBracketTournamentService.parseBracket(data, bracketID: bracketID) {
                    continuation.yield(bracket)
                }
            }
            continuation.onTermination = { _ in listener.remove() }
        }
        #else
        return AsyncStream { $0.finish() }
        #endif
    }

    // MARK: - Loading

    #if canImport(FirebaseFirestore)
    private func loadBracket(bracketID: String, squadID: String, tournamentID: String) async throws -> BracketTournament {
        let snapshot = try await firestore
            .document(FirestorePaths.bracket(squadID, tournamentID, bracketID))
            .getDocument()
        guard let data = snapshot.data(),
              let bracket = bracketFrom(data, bracketID: bracketID)
        else { throw BracketTournamentServiceError.bracketNotFound }
        return bracket
    }
    #endif
}

// MARK: - Serialization

private extension FirebaseBracketTournamentService {

    func fixedTeamToDict(_ t: FixedTeam) -> [String: Any] {
        ["id": t.id, "name": t.name, "playerIDs": t.playerIDs]
    }

    func groupMatchToDict(_ m: GroupMatch) -> [String: Any] {
        var d: [String: Any] = ["id": m.id, "teamAID": m.teamAID, "teamBID": m.teamBID]
        if let a = m.scoreA       { d["scoreA"] = a }
        if let b = m.scoreB       { d["scoreB"] = b }
        if let w = m.winnerTeamID { d["winnerTeamID"] = w }
        if let t = m.completedAt  { d["completedAt"] = t }
        return d
    }

    func groupToDict(_ g: BracketGroup) -> [String: Any] {
        var d: [String: Any] = [
            "id": g.id,
            "name": g.name,
            "teams": g.teams.map(fixedTeamToDict),
            "matches": g.matches.map(groupMatchToDict)
        ]
        if let n = g.advanceCount { d["advanceCount"] = n }
        return d
    }

    func setScoreToDict(_ s: SetScore) -> [String: Any] {
        ["teamAScore": s.teamAScore, "teamBScore": s.teamBScore]
    }

    func knockoutMatchToDict(_ m: KnockoutMatch) -> [String: Any] {
        var d: [String: Any] = [
            "id": m.id,
            "round": m.round.rawValue,
            "position": m.position,
            "sets": m.sets.map(setScoreToDict)
        ]
        if let a = m.teamAID      { d["teamAID"] = a }
        if let b = m.teamBID      { d["teamBID"] = b }
        if let w = m.winnerTeamID { d["winnerTeamID"] = w }
        if let t = m.completedAt  { d["completedAt"] = t }
        return d
    }

    func bracketToDict(_ b: BracketTournament) -> [String: Any] {
        [
            "id": b.id,
            "parentTournamentID": b.parentTournamentID,
            "squadID": b.squadID,
            "createdBy": b.createdBy,
            "createdAt": b.createdAt,
            "title": b.title,
            "status": b.status.rawValue,
            "groups": b.groups.map(groupToDict),
            "knockoutBestOf": b.knockoutBestOf,
            "knockoutMatches": b.knockoutMatches.map(knockoutMatchToDict)
        ]
    }

    #if canImport(FirebaseFirestore)
    func bracketFrom(_ d: [String: Any], bracketID: String) -> BracketTournament? {
        FirebaseBracketTournamentService.parseBracket(d, bracketID: bracketID)
    }
    #endif
}

// MARK: - Static parsers (usable from nonisolated context)

private extension FirebaseBracketTournamentService {
    #if canImport(FirebaseFirestore)
    static func parseBracket(_ d: [String: Any], bracketID: String) -> BracketTournament? {
        guard let parentTournamentID = d["parentTournamentID"] as? String,
              let squadID = d["squadID"] as? String,
              let createdBy = d["createdBy"] as? String,
              let title = d["title"] as? String,
              let statusRaw = d["status"] as? String,
              let status = BracketStatus(rawValue: statusRaw)
        else { return nil }
        let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? .now
        let groups = (d["groups"] as? [[String: Any]] ?? []).compactMap(parseGroup)
        let knockoutBestOf = d["knockoutBestOf"] as? Int ?? 0
        let knockoutMatches = (d["knockoutMatches"] as? [[String: Any]] ?? []).compactMap(parseKnockoutMatch)
        return BracketTournament(
            id: bracketID,
            parentTournamentID: parentTournamentID,
            squadID: squadID,
            createdBy: createdBy,
            createdAt: createdAt,
            title: title,
            status: status,
            groups: groups,
            knockoutBestOf: knockoutBestOf,
            knockoutMatches: knockoutMatches
        )
    }

    static func parseGroup(_ d: [String: Any]) -> BracketGroup? {
        guard let id = d["id"] as? String,
              let name = d["name"] as? String else { return nil }
        let teams = (d["teams"] as? [[String: Any]] ?? []).compactMap(parseFixedTeam)
        let matches = (d["matches"] as? [[String: Any]] ?? []).compactMap(parseGroupMatch)
        return BracketGroup(
            id: id, name: name, teams: teams, matches: matches,
            advanceCount: d["advanceCount"] as? Int
        )
    }

    static func parseFixedTeam(_ d: [String: Any]) -> FixedTeam? {
        guard let id = d["id"] as? String,
              let name = d["name"] as? String,
              let playerIDs = d["playerIDs"] as? [String] else { return nil }
        return FixedTeam(id: id, name: name, playerIDs: playerIDs)
    }

    static func parseGroupMatch(_ d: [String: Any]) -> GroupMatch? {
        guard let id = d["id"] as? String,
              let teamAID = d["teamAID"] as? String,
              let teamBID = d["teamBID"] as? String else { return nil }
        return GroupMatch(
            id: id, teamAID: teamAID, teamBID: teamBID,
            scoreA: d["scoreA"] as? Int,
            scoreB: d["scoreB"] as? Int,
            winnerTeamID: d["winnerTeamID"] as? String,
            completedAt: (d["completedAt"] as? Timestamp)?.dateValue()
        )
    }

    static func parseKnockoutMatch(_ d: [String: Any]) -> KnockoutMatch? {
        guard let id = d["id"] as? String,
              let roundRaw = d["round"] as? String,
              let round = KnockoutRound(rawValue: roundRaw),
              let position = d["position"] as? Int
        else { return nil }
        let sets = (d["sets"] as? [[String: Any]] ?? []).compactMap(parseSet)
        return KnockoutMatch(
            id: id, round: round, position: position,
            teamAID: d["teamAID"] as? String,
            teamBID: d["teamBID"] as? String,
            sets: sets,
            winnerTeamID: d["winnerTeamID"] as? String,
            completedAt: (d["completedAt"] as? Timestamp)?.dateValue()
        )
    }

    static func parseSet(_ d: [String: Any]) -> SetScore? {
        guard let a = d["teamAScore"] as? Int,
              let b = d["teamBScore"] as? Int else { return nil }
        return SetScore(teamAScore: a, teamBScore: b)
    }
    #endif
}
