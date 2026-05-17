import Foundation

/// Pure logic for bracket tournaments — group round-robin generation, standings,
/// knockout pairing, and round advancement. No I/O, no SDK imports.
enum BracketEngine {

    // MARK: - Group stage

    /// Generates the round-robin matchups for a group: every team plays every other team once.
    static func generateGroupMatches(teams: [FixedTeam]) -> [GroupMatch] {
        var matches: [GroupMatch] = []
        guard teams.count >= 2 else { return matches }
        for i in 0..<(teams.count - 1) {
            for j in (i + 1)..<teams.count {
                matches.append(GroupMatch(
                    id: UUID().uuidString,
                    teamAID: teams[i].id,
                    teamBID: teams[j].id,
                    scoreA: nil, scoreB: nil,
                    winnerTeamID: nil, completedAt: nil
                ))
            }
        }
        return matches
    }

    /// Sorted team IDs by group standings: wins desc → losses asc → point diff desc → name.
    /// Stable for unit testing; no random tiebreak.
    static func standings(for group: BracketGroup) -> [String] {
        struct Standing { let teamID: String; let name: String; let wins: Int; let losses: Int; let diff: Int }

        let standings: [Standing] = group.teams.map { team in
            var wins = 0, losses = 0, diff = 0
            for m in group.matches where m.completedAt != nil {
                if m.teamAID == team.id, let a = m.scoreA, let b = m.scoreB {
                    diff += (a - b)
                    if m.winnerTeamID == team.id { wins += 1 } else { losses += 1 }
                } else if m.teamBID == team.id, let a = m.scoreA, let b = m.scoreB {
                    diff += (b - a)
                    if m.winnerTeamID == team.id { wins += 1 } else { losses += 1 }
                }
            }
            return Standing(teamID: team.id, name: team.name, wins: wins, losses: losses, diff: diff)
        }

        return standings.sorted { a, b in
            if a.wins != b.wins   { return a.wins > b.wins }
            if a.losses != b.losses { return a.losses < b.losses }
            if a.diff != b.diff   { return a.diff > b.diff }
            return a.name < b.name
        }.map(\.teamID)
    }

    /// True when every match in every group has a winner.
    static func groupStageComplete(_ bracket: BracketTournament) -> Bool {
        bracket.groups.allSatisfy { g in g.matches.allSatisfy { $0.winnerTeamID != nil } }
    }

    // MARK: - Knockout pairing

    /// Number of sets a team must win to take a match in best-of-N.
    static func setsToWin(bestOf: Int) -> Int { (bestOf + 1) / 2 }

    /// Determines the starting knockout round for a given number of advancing teams.
    /// Returns nil if the count is unsupported (>8 or <2).
    static func startingRound(for advancingTeamCount: Int) -> KnockoutRound? {
        switch advancingTeamCount {
        case 2:       return .final
        case 3, 4:    return .semifinal
        case 5...8:   return .quarterfinal
        default:      return nil
        }
    }

    /// Random initial pairing: shuffles team IDs, slots into match positions.
    /// Odd count → last team gets a bye (teamBID == nil, auto-wins).
    static func pairInitialMatches(teamIDs: [String], round: KnockoutRound, now: Date = .now) -> [KnockoutMatch] {
        let shuffled = teamIDs.shuffled()
        var matches: [KnockoutMatch] = []
        var position = 0
        var i = 0
        while i < shuffled.count {
            let teamA: String? = shuffled[i]
            let teamB: String? = (i + 1 < shuffled.count) ? shuffled[i + 1] : nil
            let isBye = teamB == nil
            matches.append(KnockoutMatch(
                id: UUID().uuidString,
                round: round, position: position,
                teamAID: teamA, teamBID: teamB,
                sets: [],
                winnerTeamID: isBye ? teamA : nil,
                completedAt: isBye ? now : nil
            ))
            position += 1
            i += 2
        }
        return matches
    }

    // MARK: - Round advancement

    /// If the current round is fully decided, generates the next round's matches.
    /// Mutates `bracket.knockoutMatches`. Idempotent — safe to call after any write.
    /// Also flips status to `.finished` when the Final is decided.
    static func advanceBracketIfReady(_ bracket: inout BracketTournament, now: Date = .now) {
        let rounds: [KnockoutRound] = [.quarterfinal, .semifinal, .final, .thirdPlace]

        for round in rounds {
            let inRound = bracket.knockoutMatches.filter { $0.round == round }.sorted { $0.position < $1.position }
            guard !inRound.isEmpty else { continue }
            let allDecided = inRound.allSatisfy { $0.winnerTeamID != nil }
            guard allDecided else { continue }

            switch round {
            case .quarterfinal:
                if !bracket.knockoutMatches.contains(where: { $0.round == .semifinal }) {
                    let winners = inRound.compactMap(\.winnerTeamID)
                    bracket.knockoutMatches.append(contentsOf: makePairedRound(.semifinal, teamIDs: winners, now: now))
                }
            case .semifinal:
                if !bracket.knockoutMatches.contains(where: { $0.round == .final }) {
                    let winners = inRound.compactMap(\.winnerTeamID)
                    bracket.knockoutMatches.append(contentsOf: makePairedRound(.final, teamIDs: winners, now: now))

                    let losers: [String] = inRound.compactMap { m in
                        guard let winner = m.winnerTeamID else { return nil }
                        if m.teamAID == winner { return m.teamBID }
                        if m.teamBID == winner { return m.teamAID }
                        return nil
                    }
                    if losers.count == 2 {
                        bracket.knockoutMatches.append(contentsOf: makePairedRound(.thirdPlace, teamIDs: losers, now: now))
                    }
                }
            case .final:
                bracket.status = .finished
            case .thirdPlace:
                break // doesn't gate finished status
            }
        }
    }

    /// Pairs winners sequentially into the next round: positions 2N and 2N+1 meet.
    /// Used after rounds where we know exactly how many teams advance (no byes mid-bracket).
    private static func makePairedRound(_ round: KnockoutRound, teamIDs: [String], now: Date) -> [KnockoutMatch] {
        var matches: [KnockoutMatch] = []
        var position = 0
        var i = 0
        while i < teamIDs.count {
            let teamA: String? = teamIDs[i]
            let teamB: String? = (i + 1 < teamIDs.count) ? teamIDs[i + 1] : nil
            let isBye = teamB == nil
            matches.append(KnockoutMatch(
                id: UUID().uuidString,
                round: round, position: position,
                teamAID: teamA, teamBID: teamB,
                sets: [],
                winnerTeamID: isBye ? teamA : nil,
                completedAt: isBye ? now : nil
            ))
            position += 1
            i += 2
        }
        return matches
    }

    // MARK: - Set entry

    /// Appends a set to the match. If a team has now won `setsToWin(bestOf:)` sets,
    /// stamps the winnerTeamID and completedAt. Returns the mutated match.
    static func applySet(_ match: KnockoutMatch, set: SetScore, bestOf: Int, now: Date = .now) -> KnockoutMatch {
        var updated = match
        updated.sets.append(set)

        let setsA = updated.sets.filter { $0.teamAScore > $0.teamBScore }.count
        let setsB = updated.sets.filter { $0.teamBScore > $0.teamAScore }.count
        let target = setsToWin(bestOf: bestOf)

        if setsA >= target, let teamA = updated.teamAID {
            updated.winnerTeamID = teamA
            updated.completedAt = now
        } else if setsB >= target, let teamB = updated.teamBID {
            updated.winnerTeamID = teamB
            updated.completedAt = now
        }
        return updated
    }
}
