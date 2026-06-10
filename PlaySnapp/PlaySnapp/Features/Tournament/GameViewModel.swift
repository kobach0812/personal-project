import Combine
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var session: GameSession?
    @Published var game: Game?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var observerTask: Task<Void, Never>?

    var isOrganizer: Bool {
        guard let game, let user = currentUser else { return false }
        return game.createdBy == user.id
    }

    /// Non-nil when the current user has a linked player in the active round.
    var participantBannerText: String? {
        guard let session, let user = currentUser else { return nil }
        guard let myPlayer = session.players.first(where: { $0.userID == user.id }) else { return nil }
        guard let match = session.currentRound.first(where: {
            $0.teamA.contains(myPlayer.id) || $0.teamB.contains(myPlayer.id)
        }) else { return nil }
        return "You're on Court \(match.court)"
    }

    var billboardPlayers: [GamePlayer] {
        guard let session else { return [] }
        return session.players.sorted {
            if $0.wins != $1.wins     { return $0.wins > $1.wins }
            if $0.losses != $1.losses { return $0.losses < $1.losses }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Active players not currently assigned to any court.
    var sittingOut: [GamePlayer] {
        guard let session else { return [] }
        let activeIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        return session.players.filter { $0.isActive && !activeIDs.contains($0.id) }
    }

    /// Players benched by the organizer for this day.
    var benched: [GamePlayer] {
        session?.players.filter { !$0.isActive } ?? []
    }

    func playerName(_ id: String) -> String {
        session?.players.first { $0.id == id }?.name ?? id
    }

    // MARK: - Loading

    func loadDay(
        _ session: GameSession,
        game: Game,
        currentUser: AppUser?,
        gameService: GameServicing
    ) async {
        self.session     = session
        self.game  = game
        self.currentUser = currentUser
        if let matches = try? await gameService.fetchMatches(for: session) {
            self.session?.completedMatches = matches
        }
        startObserving(session: session, gameService: gameService)
    }

    private func startObserving(session: GameSession, gameService: GameServicing) {
        observerTask?.cancel()
        observerTask = Task {
            let stream = gameService.observeSession(
                squadID: session.squadID,
                gameID: session.gameID,
                sessionID: session.id
            )
            for await fresh in stream {
                guard !Task.isCancelled else { break }
                // Preserve locally loaded completedMatches (they come from a subcollection, not the session doc)
                let existing = self.session?.completedMatches ?? []
                self.session = fresh
                if self.session?.completedMatches.isEmpty == true {
                    self.session?.completedMatches = existing
                }
            }
        }
    }

    // MARK: - Match actions

    func recordResult(matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?, gameService: GameServicing) async {
        guard let session else { return }
        do {
            self.session = try await gameService.recordResult(
                for: session, matchID: matchID, winner: winner, scoreA: scoreA, scoreB: scoreB
            )
        } catch {
            errorMessage = "Could not save result."
        }
    }

    // MARK: - Day lifecycle

    func endDay(gameService: GameServicing) async {
        guard let session, let game else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await gameService.endDay(session, for: game)
            self.game = updated
            self.session?.status = .finished
        } catch {
            errorMessage = "Could not end day."
        }
    }

    // MARK: - Player management (organizer only)

    func benchPlayer(_ playerID: String, gameService: GameServicing) async {
        guard var players = session?.players,
              let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        let onCourt = session?.currentRound.flatMap { $0.teamA + $0.teamB }.contains(playerID) ?? false
        guard !onCourt else { errorMessage = "Can't bench someone currently on court."; return }
        players[idx].isActive = false
        await pushPlayerUpdate(players, gameService: gameService)
    }

    func restorePlayer(_ playerID: String, gameService: GameServicing) async {
        guard var players = session?.players,
              let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[idx].isActive = true
        await pushPlayerUpdate(players, gameService: gameService)
    }

    func removePlayer(_ playerID: String, gameService: GameServicing) async {
        guard let players = session?.players else { return }
        let onCourt = session?.currentRound.flatMap { $0.teamA + $0.teamB }.contains(playerID) ?? false
        guard !onCourt else { errorMessage = "Can't remove someone currently on court."; return }
        await pushPlayerUpdate(players.filter { $0.id != playerID }, gameService: gameService)
    }

    private func pushPlayerUpdate(_ players: [GamePlayer], gameService: GameServicing) async {
        guard let session else { return }
        do {
            self.session = try await gameService.updatePlayers(players, for: session)
        } catch {
            errorMessage = "Could not update players."
        }
    }

    // MARK: - Participant self-actions

    /// Participant benches or restores themselves. Only valid when the player is not currently on court.
    func selfBenchToggle(gameService: GameServicing) async {
        guard let session, let user = currentUser,
              let myPlayer = session.players.first(where: { $0.userID == user.id }) else { return }
        let onCourt = session.currentRound.flatMap { $0.teamA + $0.teamB }.contains(myPlayer.id)
        guard !onCourt else { return }
        do {
            self.session = try await gameService.setSelfBench(
                playerID: myPlayer.id,
                isActive: !myPlayer.isActive,
                for: session
            )
        } catch {
            errorMessage = "Could not update your status."
        }
    }

    var myPlayer: GamePlayer? {
        guard let session, let user = currentUser else { return nil }
        return session.players.first { $0.userID == user.id }
    }

    var myPlayerIsOnCourt: Bool {
        guard let session, let player = myPlayer else { return false }
        return session.currentRound.flatMap { $0.teamA + $0.teamB }.contains(player.id)
    }

    // MARK: - Fixed teams

    /// Returns the fixed-team name whose playerIDs match the given IDs (order-insensitive). Nil in rotation mode.
    func fixedTeamName(for playerIDs: [String]) -> String? {
        guard let session, session.mode == .fixedTeams else { return nil }
        let set = Set(playerIDs)
        return session.fixedTeams.first { Set($0.playerIDs) == set }?.name
    }

    func setFixedTeams(_ teams: [FixedTeam], gameService: GameServicing) async {
        guard let session else { return }
        do {
            self.session = try await gameService.setFixedTeams(teams, for: session)
        } catch {
            errorMessage = "Could not save fixed teams."
        }
    }

}
