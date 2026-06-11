import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private let now = Date(timeIntervalSince1970: 1_750_000_000)

private func player(_ name: String, wins: Int = 0, losses: Int = 0, played: Int = 0) -> GamePlayer {
    GamePlayer(
        id: name.lowercased(), name: name, userID: name.lowercased(),
        played: played, wins: wins, losses: losses,
        lastPlayedAt: 0, isActive: true
    )
}

private func session(players: [GamePlayer], title: String = "Tuesday 8pm", endedAt: Date? = nil) -> GameSession {
    GameSession(
        id: "s1", gameID: "g1", squadID: "sq1",
        createdBy: "host", createdAt: now,
        title: title, status: .finished,
        courts: 1, players: players,
        currentRound: [], roundNumber: 0,
        matchCounter: 0, completedMatches: [],
        partnerships: [:],
        participantUserIDs: players.compactMap(\.userID),
        endedAt: endedAt, scheduledStart: nil, location: nil,
        mode: .rotation, fixedTeams: []
    )
}

private func match(_ id: String, scoreA: Int? = nil, scoreB: Int? = nil, winner: WinnerTeam = .teamA) -> GameMatch {
    GameMatch(
        id: id, court: 1,
        teamA: ["alice", "bob"], teamB: ["carol", "dave"],
        winnerTeam: winner, teamAScore: scoreA, teamBScore: scoreB,
        completedAt: now
    )
}

private func bracketFixture(champion: FixedTeam) -> BracketTournament {
    let runnerUp = FixedTeam(id: "t2", name: "Team 2", playerIDs: ["carol", "dave"])
    let group = BracketGroup(
        id: "gA", name: "A",
        teams: [champion, runnerUp],
        matches: [
            GroupMatch(id: "m1", teamAID: champion.id, teamBID: runnerUp.id,
                       scoreA: 21, scoreB: 15, winnerTeamID: champion.id, completedAt: now),
        ],
        advanceCount: 2
    )
    let final = KnockoutMatch(
        id: "k1", round: .final, position: 0,
        teamAID: champion.id, teamBID: runnerUp.id,
        sets: [SetScore(teamAScore: 21, teamBScore: 18)],
        winnerTeamID: champion.id, completedAt: now
    )
    return BracketTournament(
        id: "b1", parentTournamentID: "g1", squadID: "sq1",
        createdBy: "host", createdAt: now,
        title: "Spring Cup", status: .finished,
        groups: [group], knockoutBestOf: 1, knockoutMatches: [final]
    )
}

// MARK: - Day session variant

struct GameDayRecapBuilderSessionTests {

    @Test
    func basicCounts_comeFromSessionAndMatches() {
        let s = session(players: [player("Alice"), player("Bob"), player("Carol"), player("Dave")])
        let recap = GameDayRecapBuilder.build(session: s, matches: [match("m1"), match("m2")], now: now)
        #expect(recap.gameTitle == "Tuesday 8pm")
        #expect(recap.playerCount == 4)
        #expect(recap.matchCount == 2)
        #expect(recap.championTeamName == nil)
    }

    @Test
    func date_prefersEndedAt_fallsBackToNow() {
        let ended = now.addingTimeInterval(-3_600)
        let withEnd = GameDayRecapBuilder.build(
            session: session(players: [], endedAt: ended), matches: [], now: now
        )
        let withoutEnd = GameDayRecapBuilder.build(
            session: session(players: []), matches: [], now: now
        )
        #expect(withEnd.date == ended)
        #expect(withoutEnd.date == now)
    }

    @Test
    func topPerformer_isThePlayerWithMostWins() {
        let s = session(players: [
            player("Alice", wins: 3, played: 5),
            player("Bob", wins: 5, played: 6),
            player("Carol", wins: 1, played: 4),
        ])
        let recap = GameDayRecapBuilder.build(session: s, matches: [match("m1")], now: now)
        #expect(recap.topPerformerName == "Bob")
    }

    @Test
    func topPerformer_winsTie_breaksByMostPlayedThenName() {
        let s = session(players: [
            player("Zoe", wins: 2, played: 3),
            player("Alice", wins: 2, played: 3),
            player("Bob", wins: 2, played: 5),
        ])
        let recap = GameDayRecapBuilder.build(session: s, matches: [match("m1")], now: now)
        #expect(recap.topPerformerName == "Bob")

        let tieOnBoth = session(players: [
            player("Zoe", wins: 2, played: 3),
            player("Alice", wins: 2, played: 3),
        ])
        let recap2 = GameDayRecapBuilder.build(session: tieOnBoth, matches: [match("m1")], now: now)
        #expect(recap2.topPerformerName == "Alice")
    }

    @Test
    func topPerformer_isNilWhenNobodyWon() {
        let s = session(players: [player("Alice"), player("Bob")])
        let recap = GameDayRecapBuilder.build(session: s, matches: [], now: now)
        #expect(recap.topPerformerName == nil)
    }

    @Test
    func biggestScoreline_picksTheLargestMargin_winnerScoreFirst() {
        let matches = [
            match("m1", scoreA: 21, scoreB: 18),
            match("m2", scoreA: 9, scoreB: 21, winner: .teamB),
            match("m3", scoreA: 21, scoreB: 15),
        ]
        let s = session(players: [player("Alice", wins: 1)])
        let recap = GameDayRecapBuilder.build(session: s, matches: matches, now: now)
        #expect(recap.biggestScoreline == "21–9")
    }

    @Test
    func biggestScoreline_isNilWhenNoMatchHasScores() {
        let s = session(players: [player("Alice", wins: 1)])
        let recap = GameDayRecapBuilder.build(session: s, matches: [match("m1")], now: now)
        #expect(recap.biggestScoreline == nil)
    }
}

// MARK: - Bracket champion variant

struct GameDayRecapBuilderBracketTests {

    @Test
    func bracketRecap_carriesChampionTitleAndCounts() {
        let champion = FixedTeam(id: "t1", name: "Team 1", playerIDs: ["alice", "bob"])
        let recap = GameDayRecapBuilder.build(bracket: bracketFixture(champion: champion), champion: champion, now: now)
        #expect(recap.gameTitle == "Spring Cup")
        #expect(recap.championTeamName == "Team 1")
        // 1 completed group match + 1 completed knockout match
        #expect(recap.matchCount == 2)
        // 4 distinct players across the two teams
        #expect(recap.playerCount == 4)
        #expect(recap.topPerformerName == nil)
        #expect(recap.biggestScoreline == nil)
        #expect(recap.date == now)
    }
}
