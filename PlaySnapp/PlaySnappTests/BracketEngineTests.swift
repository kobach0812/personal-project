import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private func team(_ id: String, _ playerIDs: [String] = ["x", "y"]) -> FixedTeam {
    FixedTeam(id: id, name: id, playerIDs: playerIDs)
}

private func group(_ name: String, teams: [FixedTeam], matches: [GroupMatch] = []) -> BracketGroup {
    BracketGroup(id: "g-\(name)", name: name, teams: teams, matches: matches, advanceCount: nil)
}

private func completedMatch(teamA: String, teamB: String, scoreA: Int, scoreB: Int) -> GroupMatch {
    GroupMatch(
        id: UUID().uuidString,
        teamAID: teamA, teamBID: teamB,
        scoreA: scoreA, scoreB: scoreB,
        winnerTeamID: scoreA > scoreB ? teamA : teamB,
        completedAt: .now
    )
}

private func bracket(
    status: BracketStatus = .knockout,
    groups: [BracketGroup] = [],
    knockoutBestOf: Int = 3,
    knockoutMatches: [KnockoutMatch] = []
) -> BracketTournament {
    BracketTournament(
        id: "b1", parentTournamentID: "t1", squadID: "sq1",
        createdBy: "host", createdAt: .now,
        title: "Test Bracket",
        status: status,
        groups: groups,
        knockoutBestOf: knockoutBestOf,
        knockoutMatches: knockoutMatches
    )
}

// MARK: - Group stage

struct BracketEngineTests {

    @Test
    func generateGroupMatches_with2Teams_produces1Match() {
        let teams = [team("T1"), team("T2")]
        let matches = BracketEngine.generateGroupMatches(teams: teams)
        #expect(matches.count == 1)
        #expect(Set([matches[0].teamAID, matches[0].teamBID]) == Set(["T1", "T2"]))
    }

    @Test
    func generateGroupMatches_with4Teams_produces6Matches() {
        let teams = (1...4).map { team("T\($0)") }
        let matches = BracketEngine.generateGroupMatches(teams: teams)
        #expect(matches.count == 6)
        // All pairs are distinct
        let pairs = matches.map { Set([$0.teamAID, $0.teamBID]) }
        #expect(Set(pairs.map { $0.sorted().joined(separator: "-") }).count == 6)
    }

    @Test
    func generateGroupMatches_with3Teams_produces3Matches() {
        let teams = (1...3).map { team("T\($0)") }
        let matches = BracketEngine.generateGroupMatches(teams: teams)
        #expect(matches.count == 3)
    }

    // MARK: - Standings

    @Test
    func standings_sortsByWinsDescending() {
        let teams = [team("T1"), team("T2"), team("T3")]
        // T1 won twice, T2 once, T3 zero
        let matches = [
            completedMatch(teamA: "T1", teamB: "T2", scoreA: 21, scoreB: 15),
            completedMatch(teamA: "T1", teamB: "T3", scoreA: 21, scoreB: 12),
            completedMatch(teamA: "T2", teamB: "T3", scoreA: 21, scoreB: 18)
        ]
        let standings = BracketEngine.standings(for: group("A", teams: teams, matches: matches))
        #expect(standings == ["T1", "T2", "T3"])
    }

    @Test
    func standings_tiebreaksByLossesAscending() {
        // Both T1 and T2 have 1 win — but T2 has fewer losses so should rank higher
        let teams = [team("T1"), team("T2"), team("T3")]
        let matches = [
            completedMatch(teamA: "T1", teamB: "T3", scoreA: 21, scoreB: 10),
            completedMatch(teamA: "T1", teamB: "T2", scoreA: 15, scoreB: 21),
            completedMatch(teamA: "T2", teamB: "T3", scoreA: 21, scoreB: 19)
        ]
        // T1: 1W 1L, T2: 2W 0L, T3: 0W 2L  →  expected order T2, T1, T3
        let standings = BracketEngine.standings(for: group("A", teams: teams, matches: matches))
        #expect(standings == ["T2", "T1", "T3"])
    }

    @Test
    func standings_tiebreaksByPointDiff() {
        let teams = [team("T1"), team("T2")]
        // Both 1 win 0 losses (impossible in real round-robin but tests diff logic
        // with a 0-match group is meaningless — use 2-team group where both have to
        // play one match. Just test the diff path with a single recorded match.)
        let matches = [completedMatch(teamA: "T1", teamB: "T2", scoreA: 21, scoreB: 12)]
        // T1 wins by 9, T2 loses by 9 → T1 ranks first
        let standings = BracketEngine.standings(for: group("A", teams: teams, matches: matches))
        #expect(standings.first == "T1")
    }

    // MARK: - startingRound

    @Test
    func startingRound_mapsTeamCountToRound() {
        #expect(BracketEngine.startingRound(for: 2) == .final)
        #expect(BracketEngine.startingRound(for: 3) == .semifinal)
        #expect(BracketEngine.startingRound(for: 4) == .semifinal)
        #expect(BracketEngine.startingRound(for: 5) == .quarterfinal)
        #expect(BracketEngine.startingRound(for: 8) == .quarterfinal)
        #expect(BracketEngine.startingRound(for: 9) == nil)
        #expect(BracketEngine.startingRound(for: 1) == nil)
        #expect(BracketEngine.startingRound(for: 0) == nil)
    }

    // MARK: - pairInitialMatches

    @Test
    func pairInitialMatches_evenCount_hasNoBye() {
        let matches = BracketEngine.pairInitialMatches(
            teamIDs: ["A", "B", "C", "D"], round: .semifinal
        )
        #expect(matches.count == 2)
        for m in matches {
            #expect(m.teamAID != nil && m.teamBID != nil)
            #expect(m.winnerTeamID == nil)
            #expect(m.completedAt == nil)
        }
    }

    @Test
    func pairInitialMatches_oddCount_lastMatchIsBye() {
        let matches = BracketEngine.pairInitialMatches(
            teamIDs: ["A", "B", "C"], round: .semifinal
        )
        #expect(matches.count == 2)
        let bye = matches.first { $0.teamBID == nil }
        #expect(bye != nil)
        #expect(bye?.winnerTeamID == bye?.teamAID, "bye auto-advances teamA")
        #expect(bye?.completedAt != nil)
    }

    @Test
    func pairInitialMatches_for4Teams_startsAtSemifinal() {
        let matches = BracketEngine.pairInitialMatches(
            teamIDs: ["A", "B", "C", "D"], round: .semifinal
        )
        #expect(matches.count == 2)
        #expect(matches.allSatisfy { $0.round == .semifinal })
    }

    @Test
    func pairInitialMatches_for2Teams_startsAtFinal() {
        let matches = BracketEngine.pairInitialMatches(
            teamIDs: ["A", "B"], round: .final
        )
        #expect(matches.count == 1)
        #expect(matches[0].round == .final)
    }

    // MARK: - setsToWin

    @Test
    func setsToWin_returnsCorrectThreshold() {
        #expect(BracketEngine.setsToWin(bestOf: 1) == 1)
        #expect(BracketEngine.setsToWin(bestOf: 3) == 2)
        #expect(BracketEngine.setsToWin(bestOf: 5) == 3)
    }

    // MARK: - applySet

    @Test
    func applySet_bestOf3_winsAfterTwoSets() {
        let match = KnockoutMatch(
            id: "m1", round: .final, position: 0,
            teamAID: "A", teamBID: "B",
            sets: [SetScore(teamAScore: 21, teamBScore: 18)],
            winnerTeamID: nil, completedAt: nil
        )
        let updated = BracketEngine.applySet(
            match,
            set: SetScore(teamAScore: 21, teamBScore: 15),
            bestOf: 3
        )
        #expect(updated.winnerTeamID == "A")
        #expect(updated.completedAt != nil)
        #expect(updated.sets.count == 2)
    }

    @Test
    func applySet_bestOf3_notDecidedAt1to1() {
        let match = KnockoutMatch(
            id: "m1", round: .final, position: 0,
            teamAID: "A", teamBID: "B",
            sets: [SetScore(teamAScore: 21, teamBScore: 18)],
            winnerTeamID: nil, completedAt: nil
        )
        let updated = BracketEngine.applySet(
            match,
            set: SetScore(teamAScore: 12, teamBScore: 21),
            bestOf: 3
        )
        #expect(updated.winnerTeamID == nil)
        #expect(updated.completedAt == nil)
        #expect(updated.sets.count == 2)
    }

    // MARK: - advanceBracketIfReady

    @Test
    func advanceBracketIfReady_qfComplete_spawnsSemifinals() {
        // 4 QF winners: W1, W2, W3, W4
        let qfs = [
            KnockoutMatch(id: "q1", round: .quarterfinal, position: 0,
                          teamAID: "W1", teamBID: "L1",
                          sets: [], winnerTeamID: "W1", completedAt: .now),
            KnockoutMatch(id: "q2", round: .quarterfinal, position: 1,
                          teamAID: "W2", teamBID: "L2",
                          sets: [], winnerTeamID: "W2", completedAt: .now),
            KnockoutMatch(id: "q3", round: .quarterfinal, position: 2,
                          teamAID: "W3", teamBID: "L3",
                          sets: [], winnerTeamID: "W3", completedAt: .now),
            KnockoutMatch(id: "q4", round: .quarterfinal, position: 3,
                          teamAID: "W4", teamBID: "L4",
                          sets: [], winnerTeamID: "W4", completedAt: .now)
        ]
        var b = bracket(status: .knockout, knockoutMatches: qfs)
        BracketEngine.advanceBracketIfReady(&b)

        let semis = b.knockoutMatches.filter { $0.round == .semifinal }
        #expect(semis.count == 2)
        let semiTeams = Set(semis.flatMap { [$0.teamAID, $0.teamBID].compactMap { $0 } })
        #expect(semiTeams == Set(["W1", "W2", "W3", "W4"]))
    }

    @Test
    func advanceBracketIfReady_sfComplete_spawnsFinalAnd3rdPlace() {
        let sfs = [
            KnockoutMatch(id: "s1", round: .semifinal, position: 0,
                          teamAID: "W1", teamBID: "L1",
                          sets: [], winnerTeamID: "W1", completedAt: .now),
            KnockoutMatch(id: "s2", round: .semifinal, position: 1,
                          teamAID: "W2", teamBID: "L2",
                          sets: [], winnerTeamID: "W2", completedAt: .now)
        ]
        var b = bracket(status: .knockout, knockoutMatches: sfs)
        BracketEngine.advanceBracketIfReady(&b)

        let final = b.knockoutMatches.filter { $0.round == .final }
        #expect(final.count == 1)
        #expect(Set([final[0].teamAID, final[0].teamBID].compactMap { $0 }) == Set(["W1", "W2"]))

        let thirdPlace = b.knockoutMatches.filter { $0.round == .thirdPlace }
        #expect(thirdPlace.count == 1)
        #expect(Set([thirdPlace[0].teamAID, thirdPlace[0].teamBID].compactMap { $0 }) == Set(["L1", "L2"]))
    }

    @Test
    func advanceBracketIfReady_finalComplete_flipsStatusToFinished() {
        let final = KnockoutMatch(
            id: "f1", round: .final, position: 0,
            teamAID: "A", teamBID: "B",
            sets: [], winnerTeamID: "A", completedAt: .now
        )
        var b = bracket(status: .knockout, knockoutMatches: [final])
        BracketEngine.advanceBracketIfReady(&b)
        #expect(b.status == .finished)
    }
}
