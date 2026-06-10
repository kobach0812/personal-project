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
        let service = FailingGameService()

        await vm.loadNextScheduledSession(squadID: "sq1", gameService: service)

        #expect(vm.nextScheduledSession == nil)
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - Minimal failing GameService for the last test

private actor FailingGameService: GameServicing {
    func createGame(squadID: String, createdBy: String, title: String, players: [GamePlayer]) async throws -> Game { throw TestFailure.expected }
    func fetchGames(squadID: String) async throws -> [Game] { throw TestFailure.expected }
    func endGame(_ game: Game) async throws { throw TestFailure.expected }
    func addPlayers(_ newPlayers: [GamePlayer], to game: Game) async throws -> Game { throw TestFailure.expected }
    func setGameRoster(_ players: [GamePlayer], for game: Game) async throws -> Game { throw TestFailure.expected }
    func removePlayer(playerID: String, from game: Game) async throws -> Game { throw TestFailure.expected }
    func startDay(for game: Game, courts: Int, players: [GamePlayer], mode: SessionMode, fixedTeams: [FixedTeam]) async throws -> (Game, GameSession) { throw TestFailure.expected }
    func endDay(_ session: GameSession, for game: Game) async throws -> Game { throw TestFailure.expected }
    func fetchSessions(for game: Game) async throws -> [GameSession] { throw TestFailure.expected }
    func fetchMatches(for session: GameSession) async throws -> [GameMatch] { throw TestFailure.expected }
    nonisolated func observeSession(squadID: String, gameID: String, sessionID: String) -> AsyncStream<GameSession> { AsyncStream { $0.finish() } }
    func generateNextRound(for session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    func recordResult(for session: GameSession, matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?) async throws -> GameSession { throw TestFailure.expected }
    func updatePlayers(_ players: [GamePlayer], for session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    func setSelfBench(playerID: String, isActive: Bool, for session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    func setFixedTeams(_ teams: [FixedTeam], for session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    func scheduleSession(for game: Game, title: String, scheduledStart: Date, courts: Int, location: String?) async throws -> GameSession { throw TestFailure.expected }
    func cancelScheduledSession(_ session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    func startScheduledSession(_ session: GameSession, courts: Int, players: [GamePlayer]) async throws -> GameSession { throw TestFailure.expected }
    func setRegistrationStatus(_ status: RegistrationStatus, userID: String, name: String, for session: GameSession) async throws { throw TestFailure.expected }
    func checkInPlayer(userID: String, name: String, in session: GameSession) async throws -> GameSession { throw TestFailure.expected }
    nonisolated func observeRegistrations(for session: GameSession) -> AsyncStream<[Registration]> { AsyncStream { $0.finish() } }
    func fetchNextScheduledSession(squadID: String) async throws -> GameSession? { throw TestFailure.expected }
}
