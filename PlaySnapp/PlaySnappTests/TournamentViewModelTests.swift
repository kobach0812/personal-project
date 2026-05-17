import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private func user(_ id: String) -> AppUser {
    AppUser(id: id, name: id, avatarURL: nil, activeSquadID: "sq1", createdAt: .now, updatedAt: .now)
}

private func tournament(createdBy: String) -> Tournament {
    Tournament(
        id: "t1", squadID: "sq1", createdBy: createdBy,
        createdAt: .now, title: "Tuesday", status: .active,
        players: [], activeDayID: "s1", sessions: []
    )
}

private func player(_ id: String,
                    userID: String? = nil,
                    name: String? = nil,
                    played: Int = 0,
                    wins: Int = 0,
                    losses: Int = 0,
                    lastPlayedAt: Int = 0,
                    isActive: Bool = true) -> TournamentPlayer {
    TournamentPlayer(
        id: id, name: name ?? id, userID: userID,
        played: played, wins: wins, losses: losses,
        lastPlayedAt: lastPlayedAt, isActive: isActive
    )
}

private func match(_ id: String, court: Int, teamA: [String], teamB: [String]) -> TournamentMatch {
    TournamentMatch(id: id, court: court, teamA: teamA, teamB: teamB, winnerTeam: nil)
}

private func session(
    players: [TournamentPlayer],
    currentRound: [TournamentMatch] = [],
    mode: SessionMode = .rotation,
    fixedTeams: [FixedTeam] = []
) -> TournamentSession {
    TournamentSession(
        id: "s1", tournamentID: "t1", squadID: "sq1",
        createdBy: "host", createdAt: .now,
        title: "Day 1", status: .active,
        courts: 2, players: players,
        currentRound: currentRound, roundNumber: 0,
        matchCounter: 0, completedMatches: [],
        partnerships: [:],
        participantUserIDs: players.compactMap(\.userID),
        endedAt: nil, scheduledStart: nil, location: nil,
        mode: mode, fixedTeams: fixedTeams
    )
}

// MARK: - Tests

@MainActor
struct TournamentViewModelTests {

    @Test
    func isOrganizer_trueWhenCurrentUserCreatedTournament() {
        let vm = TournamentViewModel()
        vm.tournament = tournament(createdBy: "alice")
        vm.currentUser = user("alice")
        #expect(vm.isOrganizer)
    }

    @Test
    func isOrganizer_falseForOtherUser() {
        let vm = TournamentViewModel()
        vm.tournament = tournament(createdBy: "alice")
        vm.currentUser = user("bob")
        #expect(!vm.isOrganizer)
    }

    @Test
    func isOrganizer_falseWhenTournamentMissing() {
        let vm = TournamentViewModel()
        vm.currentUser = user("alice")
        #expect(!vm.isOrganizer)
    }

    @Test
    func participantBannerText_showsCourtNumberWhenUserOnCourt() {
        let vm = TournamentViewModel()
        vm.currentUser = user("u1")
        vm.session = session(
            players: [player("p1", userID: "u1"), player("p2", userID: "u2"),
                      player("p3", userID: "u3"), player("p4", userID: "u4")],
            currentRound: [match("m1", court: 3, teamA: ["p1", "p2"], teamB: ["p3", "p4"])]
        )
        #expect(vm.participantBannerText == "You're on Court 3")
    }

    @Test
    func participantBannerText_nilWhenUserNotOnCourt() {
        let vm = TournamentViewModel()
        vm.currentUser = user("u1")
        vm.session = session(
            players: [player("p1", userID: "u1"), player("p2", userID: "u2"),
                      player("p3", userID: "u3"), player("p4", userID: "u4"),
                      player("p5", userID: "u5")],
            currentRound: [match("m1", court: 1, teamA: ["p2", "p3"], teamB: ["p4", "p5"])]
        )
        #expect(vm.participantBannerText == nil)
    }

    @Test
    func billboardPlayers_sortsByWinsDescThenLossesAscThenName() {
        let vm = TournamentViewModel()
        vm.session = session(players: [
            player("p1", name: "Bob",     wins: 2, losses: 1),
            player("p2", name: "Alice",   wins: 3, losses: 0),
            player("p3", name: "Charlie", wins: 2, losses: 0),
            player("p4", name: "Dave",    wins: 2, losses: 1)
        ])
        let ordered = vm.billboardPlayers.map(\.name)
        // Alice (3W) > Charlie (2W/0L) > Bob (2W/1L, B<D) > Dave (2W/1L)
        #expect(ordered == ["Alice", "Charlie", "Bob", "Dave"])
    }

    @Test
    func sittingOut_includesActivePlayersNotOnCourt() {
        let vm = TournamentViewModel()
        vm.session = session(
            players: [
                player("p1"), player("p2"), player("p3"), player("p4"),
                player("p5"),                          // sitting out
                player("p6", isActive: false)          // benched, not sitting out
            ],
            currentRound: [match("m1", court: 1, teamA: ["p1", "p2"], teamB: ["p3", "p4"])]
        )
        let sittingIDs = vm.sittingOut.map(\.id)
        #expect(sittingIDs == ["p5"])
    }

    @Test
    func benched_includesOnlyInactivePlayers() {
        let vm = TournamentViewModel()
        vm.session = session(players: [
            player("p1"),
            player("p2", isActive: false),
            player("p3", isActive: false),
            player("p4")
        ])
        let benchedIDs = vm.benched.map(\.id).sorted()
        #expect(benchedIDs == ["p2", "p3"])
    }

    @Test
    func myPlayer_returnsPlayerMatchingUserID() {
        let vm = TournamentViewModel()
        vm.currentUser = user("u1")
        vm.session = session(players: [
            player("p1", userID: "u2"),
            player("p2", userID: "u1"),
            player("p3", userID: "u3")
        ])
        #expect(vm.myPlayer?.id == "p2")
    }

    @Test
    func myPlayerIsOnCourt_trueWhenAssigned() {
        let vm = TournamentViewModel()
        vm.currentUser = user("u1")
        vm.session = session(
            players: [player("p1", userID: "u1"), player("p2", userID: "u2"),
                      player("p3", userID: "u3"), player("p4", userID: "u4")],
            currentRound: [match("m1", court: 1, teamA: ["p1", "p2"], teamB: ["p3", "p4"])]
        )
        #expect(vm.myPlayerIsOnCourt)
    }

    @Test
    func playerName_returnsIDWhenNotFound() {
        let vm = TournamentViewModel()
        vm.session = session(players: [player("p1", name: "Alice")])
        #expect(vm.playerName("p1") == "Alice")
        #expect(vm.playerName("ghost") == "ghost")
    }

    @Test
    func fixedTeamName_nilInRotationMode() {
        let vm = TournamentViewModel()
        vm.session = session(
            players: [player("p1"), player("p2")],
            mode: .rotation,
            fixedTeams: [FixedTeam(id: "T1", name: "Team 1", playerIDs: ["p1", "p2"])]
        )
        #expect(vm.fixedTeamName(for: ["p1", "p2"]) == nil)
    }

    @Test
    func fixedTeamName_returnsTeamNameInFixedMode() {
        let vm = TournamentViewModel()
        vm.session = session(
            players: [player("p1"), player("p2"), player("p3"), player("p4")],
            mode: .fixedTeams,
            fixedTeams: [
                FixedTeam(id: "T1", name: "Team 1", playerIDs: ["p1", "p2"]),
                FixedTeam(id: "T2", name: "Team 2", playerIDs: ["p3", "p4"])
            ]
        )
        // Order-insensitive match
        #expect(vm.fixedTeamName(for: ["p2", "p1"]) == "Team 1")
        #expect(vm.fixedTeamName(for: ["p3", "p4"]) == "Team 2")
        #expect(vm.fixedTeamName(for: ["p1", "p3"]) == nil)
    }
}
