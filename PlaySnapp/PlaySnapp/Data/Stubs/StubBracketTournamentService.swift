import Foundation

actor StubBracketTournamentService: BracketTournamentServicing {
    private var brackets: [BracketTournament] = []

    // MARK: - Lifecycle

    func createBracket(
        in tournamentID: String,
        squadID: String,
        createdBy: String,
        title: String,
        groups: [BracketGroup]
    ) async throws -> BracketTournament {
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
        brackets.append(bracket)
        return bracket
    }

    func fetchBrackets(in tournamentID: String, squadID: String) async throws -> [BracketTournament] {
        brackets
            .filter { $0.parentTournamentID == tournamentID && $0.squadID == squadID }
            .sorted { $0.createdAt > $1.createdAt }
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
        guard let bIdx = brackets.firstIndex(where: { $0.id == bracketID }) else {
            throw BracketTournamentServiceError.bracketNotFound
        }
        var bracket = brackets[bIdx]
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

        brackets[bIdx] = bracket
        return bracket
    }

    // MARK: - Knockout

    func configureKnockout(
        bracketID: String,
        advanceCounts: [String: Int],
        bestOf: Int,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament {
        guard let bIdx = brackets.firstIndex(where: { $0.id == bracketID }) else {
            throw BracketTournamentServiceError.bracketNotFound
        }
        var bracket = brackets[bIdx]

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

        brackets[bIdx] = bracket
        return bracket
    }

    func recordKnockoutSet(
        bracketID: String,
        matchID: String,
        set: SetScore,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament {
        guard let bIdx = brackets.firstIndex(where: { $0.id == bracketID }) else {
            throw BracketTournamentServiceError.bracketNotFound
        }
        var bracket = brackets[bIdx]
        guard bracket.knockoutBestOf > 0 else { throw BracketTournamentServiceError.knockoutNotConfigured }
        guard let mIdx = bracket.knockoutMatches.firstIndex(where: { $0.id == matchID })
        else { throw BracketTournamentServiceError.bracketNotFound }

        bracket.knockoutMatches[mIdx] = BracketEngine.applySet(
            bracket.knockoutMatches[mIdx],
            set: set,
            bestOf: bracket.knockoutBestOf
        )
        BracketEngine.advanceBracketIfReady(&bracket)

        brackets[bIdx] = bracket
        return bracket
    }

    nonisolated func observeBracket(bracketID: String, squadID: String, tournamentID: String) -> AsyncStream<BracketTournament> {
        AsyncStream { $0.finish() }
    }
}
