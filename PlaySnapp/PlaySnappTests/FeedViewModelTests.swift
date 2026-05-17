import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Test double

private final class PlayServiceStub: PlayServicing, @unchecked Sendable {
    var feed: [Play] = []
    var toggledPlay: Play?
    var fetchShouldFail = false
    var toggleShouldFail = false

    func fetchFeed() async throws -> [Play] {
        if fetchShouldFail { throw TestFailure.expected }
        return feed
    }

    func postPlay(mediaURL: URL, storagePath: String?, mediaType: MediaType, caption: String?) async throws -> Play {
        throw TestFailure.expected
    }

    func toggleReaction(for playID: String, emoji: String) async throws -> Play {
        if toggleShouldFail { throw TestFailure.expected }
        guard let toggled = toggledPlay else { throw TestFailure.expected }
        return toggled
    }
}

private func play(_ id: String, sender: String = "u1", caption: String? = nil) -> Play {
    Play(
        id: id, squadID: "sq1", senderID: sender,
        senderName: sender, mediaType: .photo,
        mediaURL: URL(string: "https://example.com/\(id).jpg")!,
        storagePath: nil, thumbnailURL: nil,
        caption: caption, durationSeconds: nil,
        reactionSummary: [:], currentUserReaction: nil,
        createdAt: .now
    )
}

// MARK: - Tests

@MainActor
struct FeedViewModelTests {

    @Test
    func load_success_populatesPlaysAndClearsError() async {
        let vm = FeedViewModel()
        let service = PlayServiceStub()
        service.feed = [play("p1"), play("p2")]

        await vm.load(playService: service)

        #expect(vm.plays.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test
    func load_failure_setsErrorAndLeavesPlaysEmpty() async {
        let vm = FeedViewModel()
        let service = PlayServiceStub()
        service.fetchShouldFail = true

        await vm.load(playService: service)

        #expect(vm.plays.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == "Could not load the feed.")
    }

    @Test
    func toggleReaction_replacesMatchingPlay() async {
        let vm = FeedViewModel()
        let service = PlayServiceStub()
        let original = play("p1")
        var withReaction = original
        withReaction.reactionSummary = ["🔥": 1]
        withReaction.currentUserReaction = "🔥"
        vm.plays = [original, play("p2")]
        service.toggledPlay = withReaction

        await vm.toggleReaction("🔥", for: "p1", playService: service)

        #expect(vm.plays[0].reactionSummary["🔥"] == 1)
        #expect(vm.plays[1].id == "p2", "non-target play untouched")
        #expect(vm.errorMessage == nil)
    }

    @Test
    func toggleReaction_failure_setsErrorAndKeepsPlays() async {
        let vm = FeedViewModel()
        let service = PlayServiceStub()
        service.toggleShouldFail = true
        let p = play("p1")
        vm.plays = [p]

        await vm.toggleReaction("🔥", for: "p1", playService: service)

        #expect(vm.plays.count == 1)
        #expect(vm.errorMessage == "Reaction failed.")
    }

    @Test
    func loadNextScheduledSession_swallowsErrorsWithTryQuestion() async {
        // fetchNextScheduledSession is invoked via `try?`, so any error should
        // leave nextScheduledSession nil with no error message set.
        let vm = FeedViewModel()
        let service = FailingTournamentService()

        await vm.loadNextScheduledSession(squadID: "sq1", tournamentService: service)

        #expect(vm.nextScheduledSession == nil)
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - Minimal failing TournamentService for the last test

private actor FailingTournamentService: TournamentServicing {
    func createTournament(squadID: String, createdBy: String, title: String, players: [TournamentPlayer]) async throws -> Tournament { throw TestFailure.expected }
    func fetchTournaments(squadID: String) async throws -> [Tournament] { throw TestFailure.expected }
    func endTournament(_ tournament: Tournament) async throws { throw TestFailure.expected }
    func addPlayers(_ newPlayers: [TournamentPlayer], to tournament: Tournament) async throws -> Tournament { throw TestFailure.expected }
    func setTournamentRoster(_ players: [TournamentPlayer], for tournament: Tournament) async throws -> Tournament { throw TestFailure.expected }
    func startDay(for tournament: Tournament, courts: Int, players: [TournamentPlayer], mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Tournament, TournamentSession) { throw TestFailure.expected }
    func endDay(_ session: TournamentSession, for tournament: Tournament) async throws -> Tournament { throw TestFailure.expected }
    func fetchSessions(for tournament: Tournament) async throws -> [TournamentSession] { throw TestFailure.expected }
    func fetchMatches(for session: TournamentSession) async throws -> [TournamentMatch] { throw TestFailure.expected }
    nonisolated func observeSession(squadID: String, tournamentID: String, sessionID: String) -> AsyncStream<TournamentSession> { AsyncStream { $0.finish() } }
    func generateNextRound(for session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    func recordResult(for session: TournamentSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> TournamentSession { throw TestFailure.expected }
    func updatePlayers(_ players: [TournamentPlayer], for session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    func setSelfBench(playerID: String, isActive: Bool, for session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    func setFixedTeams(_ teams: [FixedTeam], for session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    func scheduleSession(for tournament: Tournament, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> TournamentSession { throw TestFailure.expected }
    func cancelScheduledSession(_ session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    func startScheduledSession(_ session: TournamentSession, courts: Int, players: [TournamentPlayer]) async throws -> TournamentSession { throw TestFailure.expected }
    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: TournamentSession) async throws { throw TestFailure.expected }
    func checkInPlayer(userID: String, name: String, in session: TournamentSession) async throws -> TournamentSession { throw TestFailure.expected }
    nonisolated func observeRegistrations(for session: TournamentSession) -> AsyncStream<[Registration]> { AsyncStream { $0.finish() } }
    func fetchNextScheduledSession(squadID: String) async throws -> TournamentSession? { throw TestFailure.expected }
}
