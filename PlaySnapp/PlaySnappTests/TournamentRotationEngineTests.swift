import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private func player(_ id: String,
                    played: Int = 0,
                    wins: Int = 0,
                    losses: Int = 0,
                    lastPlayedAt: Int = 0,
                    isActive: Bool = true) -> TournamentPlayer {
    TournamentPlayer(
        id: id, name: id, userID: id,
        played: played, wins: wins, losses: losses,
        lastPlayedAt: lastPlayedAt, isActive: isActive
    )
}

private func session(
    courts: Int,
    players: [TournamentPlayer],
    currentRound: [TournamentMatch] = [],
    completedMatches: [TournamentMatch] = [],
    matchCounter: Int = 0,
    partnerships: [String: [String: Int]] = [:],
    mode: SessionMode = .rotation,
    fixedTeams: [FixedTeam] = []
) -> TournamentSession {
    TournamentSession(
        id: "s1", tournamentID: "t1", squadID: "sq1",
        createdBy: "host", createdAt: .now,
        title: "Test Day", status: .active,
        courts: courts, players: players,
        currentRound: currentRound, roundNumber: 0,
        matchCounter: matchCounter,
        completedMatches: completedMatches,
        partnerships: partnerships,
        participantUserIDs: players.compactMap(\.userID),
        endedAt: nil, scheduledStart: nil, location: nil,
        mode: mode, fixedTeams: fixedTeams
    )
}

private func team(_ name: String, _ playerIDs: [String]) -> FixedTeam {
    FixedTeam(id: name, name: name, playerIDs: playerIDs)
}

// MARK: - Tests

struct TournamentRotationEngineTests {

    @Test
    func generateMatchForCourt_with4Players1Court_assignsAllFour() {
        let s = session(courts: 1, players: (1...4).map { player("p\($0)") })
        let match = TournamentRotationEngine.generateMatchForCourt(court: 1, session: s)
        #expect(match != nil)
        #expect(match?.court == 1)
        let all = Set((match?.teamA ?? []) + (match?.teamB ?? []))
        #expect(all == Set(["p1","p2","p3","p4"]))
        #expect(match?.teamA.count == 2)
        #expect(match?.teamB.count == 2)
    }

    @Test
    func generateMatchForCourt_with5Players1Court_leavesOneOut() {
        let s = session(courts: 1, players: (1...5).map { player("p\($0)") })
        let match = TournamentRotationEngine.generateMatchForCourt(court: 1, session: s)
        let onCourt = Set((match?.teamA ?? []) + (match?.teamB ?? []))
        #expect(onCourt.count == 4)
    }

    @Test
    func fillAllCourts_with7Players2Courts_fillsOnlyOneCourt() {
        let s = session(courts: 2, players: (1...7).map { player("p\($0)") })
        let matches = TournamentRotationEngine.fillAllCourts(session: s)
        #expect(matches.count == 1)
        let ids = matches.flatMap { $0.teamA + $0.teamB }
        #expect(Set(ids).count == ids.count)
    }

    @Test
    func fillAllCourts_with8Players2Courts_fillsBothCourts() {
        let s = session(courts: 2, players: (1...8).map { player("p\($0)") })
        let matches = TournamentRotationEngine.fillAllCourts(session: s)
        #expect(matches.count == 2)
        let ids = matches.flatMap { $0.teamA + $0.teamB }
        #expect(Set(ids).count == 8)
        #expect(Set(matches.map(\.court)) == Set([1, 2]))
    }

    @Test
    func fillAllCourts_with11Players2Courts_fillsTwoLeavesThreeOut() {
        let s = session(courts: 2, players: (1...11).map { player("p\($0)") })
        let matches = TournamentRotationEngine.fillAllCourts(session: s)
        #expect(matches.count == 2)
        let ids = matches.flatMap { $0.teamA + $0.teamB }
        #expect(Set(ids).count == 8)
    }

    @Test
    func generateMatchForCourt_prioritizesNeverPlayedOverPlayed() {
        let players = [
            player("rookie", played: 0),
            player("v1", played: 5, lastPlayedAt: 1),
            player("v2", played: 5, lastPlayedAt: 1),
            player("v3", played: 5, lastPlayedAt: 1),
            player("v4", played: 5, lastPlayedAt: 1)
        ]
        let s = session(courts: 1, players: players)
        for _ in 0..<10 {
            let match = TournamentRotationEngine.generateMatchForCourt(court: 1, session: s)
            let onCourt = Set((match?.teamA ?? []) + (match?.teamB ?? []))
            #expect(onCourt.contains("rookie"))
        }
    }

    @Test
    func generateMatchForCourt_prioritizesLongestRestedAmongEqualPlayed() {
        let players = [
            player("rested",  played: 3, lastPlayedAt: 1),
            player("recent1", played: 3, lastPlayedAt: 9),
            player("recent2", played: 3, lastPlayedAt: 10),
            player("recent3", played: 3, lastPlayedAt: 8),
            player("recent4", played: 3, lastPlayedAt: 7)
        ]
        let s = session(courts: 1, players: players)
        for _ in 0..<10 {
            let match = TournamentRotationEngine.generateMatchForCourt(court: 1, session: s)
            let onCourt = Set((match?.teamA ?? []) + (match?.teamB ?? []))
            #expect(onCourt.contains("rested"))
        }
    }

    @Test
    func generateMatchForCourt_skipsBenchedPlayers() {
        let players = [
            player("p1", isActive: false),
            player("p2"),
            player("p3"),
            player("p4"),
            player("p5")
        ]
        let s = session(courts: 1, players: players)
        for _ in 0..<10 {
            let match = TournamentRotationEngine.generateMatchForCourt(court: 1, session: s)
            let onCourt = Set((match?.teamA ?? []) + (match?.teamB ?? []))
            #expect(!onCourt.contains("p1"))
        }
    }

    // MARK: - applyResult

    @Test
    func applyResult_updatesLastPlayedAtForAllFour() {
        let players = (1...4).map { player("p\($0)", lastPlayedAt: 0) }
        let match = TournamentMatch(
            id: "m1", court: 1,
            teamA: ["p1", "p2"], teamB: ["p3", "p4"],
            winnerTeam: nil
        )
        let updated = TournamentRotationEngine.applyResult(
            players: players, match: match, winner: .teamA, matchCounter: 7
        )
        for p in updated {
            #expect(p.lastPlayedAt == 7)
            #expect(p.played == 1)
        }
    }

    @Test
    func applyResult_stampsWinsAndLossesCorrectly() {
        let players = (1...4).map { player("p\($0)") }
        let match = TournamentMatch(
            id: "m1", court: 1,
            teamA: ["p1", "p2"], teamB: ["p3", "p4"],
            winnerTeam: nil
        )
        let updated = TournamentRotationEngine.applyResult(
            players: players, match: match, winner: .teamA, matchCounter: 1
        )
        let byID = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
        #expect(byID["p1"]?.wins == 1 && byID["p1"]?.losses == 0)
        #expect(byID["p2"]?.wins == 1 && byID["p2"]?.losses == 0)
        #expect(byID["p3"]?.wins == 0 && byID["p3"]?.losses == 1)
        #expect(byID["p4"]?.wins == 0 && byID["p4"]?.losses == 1)
    }

    @Test
    func updatePartnerships_isSymmetric() {
        let match = TournamentMatch(
            id: "m1", court: 1,
            teamA: ["a", "b"], teamB: ["c", "d"],
            winnerTeam: nil
        )
        let result = TournamentRotationEngine.updatePartnerships([:], match: match)
        #expect(result["a"]?["b"] == 1)
        #expect(result["b"]?["a"] == 1)
        #expect(result["c"]?["d"] == 1)
        #expect(result["d"]?["c"] == 1)
        #expect(result["a"]?["c"] == nil)
    }

    // MARK: - Fixed-team scheduling (M20)

    @Test
    func generateFixedTeamRound_fills2Courts_noTeamRepeats() {
        let players = (1...8).map { player("p\($0)") }
        let teams = [
            team("T1", ["p1", "p2"]),
            team("T2", ["p3", "p4"]),
            team("T3", ["p5", "p6"]),
            team("T4", ["p7", "p8"])
        ]
        let s = session(courts: 2, players: players, mode: .fixedTeams, fixedTeams: teams)
        let matches = TournamentRotationEngine.generateFixedTeamRound(session: s)
        #expect(matches.count == 2)
        let allIDs = matches.flatMap { $0.teamA + $0.teamB }
        #expect(Set(allIDs).count == allIDs.count)
    }

    @Test
    func generateFixedTeamRound_picksLeastPlayedMatchup() {
        let players = (1...6).map { player("p\($0)") }
        let teams = [
            team("T1", ["p1", "p2"]),
            team("T2", ["p3", "p4"]),
            team("T3", ["p5", "p6"])
        ]
        let completedMatches = [
            TournamentMatch(id: "c1", court: 1, teamA: ["p1","p2"], teamB: ["p3","p4"], winnerTeam: .teamA),
            TournamentMatch(id: "c2", court: 1, teamA: ["p1","p2"], teamB: ["p5","p6"], winnerTeam: .teamA)
        ]
        let s = session(courts: 1, players: players, completedMatches: completedMatches,
                        mode: .fixedTeams, fixedTeams: teams)
        for _ in 0..<10 {
            let matches = TournamentRotationEngine.generateFixedTeamRound(session: s)
            #expect(matches.count == 1)
            let ids = Set((matches[0].teamA) + (matches[0].teamB))
            #expect(ids == Set(["p3","p4","p5","p6"]))
        }
    }

    @Test
    func nextFixedTeamMatch_returnsNilWhenAllTeamsBusy() {
        let players = (1...4).map { player("p\($0)") }
        let teams = [
            team("T1", ["p1", "p2"]),
            team("T2", ["p3", "p4"])
        ]
        let currentRound = [
            TournamentMatch(id: "active1", court: 1,
                            teamA: ["p1","p2"], teamB: ["p3","p4"], winnerTeam: nil)
        ]
        let s = session(courts: 2, players: players, currentRound: currentRound,
                        mode: .fixedTeams, fixedTeams: teams)
        let next = TournamentRotationEngine.nextFixedTeamMatch(court: 2, session: s)
        #expect(next == nil)
    }
}
