import Combine
import SwiftUI

@MainActor
final class TournamentViewModel: ObservableObject {
    @Published var session: TournamentSession?
    @Published var tournament: Tournament?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isOrganizer: Bool {
        guard let tournament, let user = currentUser else { return false }
        return tournament.createdBy == user.id
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

    var billboardPlayers: [TournamentPlayer] {
        guard let session else { return [] }
        return session.players.sorted {
            if $0.wins != $1.wins     { return $0.wins > $1.wins }
            if $0.losses != $1.losses { return $0.losses < $1.losses }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Active players not currently assigned to any court.
    var sittingOut: [TournamentPlayer] {
        guard let session else { return [] }
        let activeIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        return session.players.filter { $0.isActive && !activeIDs.contains($0.id) }
    }

    /// Players benched by the organizer for this day.
    var benched: [TournamentPlayer] {
        session?.players.filter { !$0.isActive } ?? []
    }

    func playerName(_ id: String) -> String {
        session?.players.first { $0.id == id }?.name ?? id
    }

    // MARK: - Loading

    func loadDay(
        _ session: TournamentSession,
        tournament: Tournament,
        currentUser: AppUser?,
        tournamentService: TournamentServicing
    ) async {
        self.session     = session
        self.tournament  = tournament
        self.currentUser = currentUser
        if let matches = try? await tournamentService.fetchMatches(for: session) {
            self.session?.completedMatches = matches
        }
    }

    // MARK: - Match actions

    func recordResult(matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?, tournamentService: TournamentServicing) async {
        guard let session else { return }
        do {
            self.session = try await tournamentService.recordResult(
                for: session, matchID: matchID, winner: winner, scoreA: scoreA, scoreB: scoreB
            )
        } catch {
            errorMessage = "Could not save result."
        }
    }

    // MARK: - Day lifecycle

    func endDay(tournamentService: TournamentServicing) async {
        guard let session, let tournament else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await tournamentService.endDay(session, for: tournament)
            self.tournament = updated
            self.session?.status = .finished
        } catch {
            errorMessage = "Could not end day."
        }
    }

    // MARK: - Player management (organizer only)

    func benchPlayer(_ playerID: String, tournamentService: TournamentServicing) async {
        guard var players = session?.players,
              let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        let onCourt = session?.currentRound.flatMap { $0.teamA + $0.teamB }.contains(playerID) ?? false
        guard !onCourt else { errorMessage = "Can't bench someone currently on court."; return }
        players[idx].isActive = false
        await pushPlayerUpdate(players, tournamentService: tournamentService)
    }

    func restorePlayer(_ playerID: String, tournamentService: TournamentServicing) async {
        guard var players = session?.players,
              let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[idx].isActive = true
        await pushPlayerUpdate(players, tournamentService: tournamentService)
    }

    func removePlayer(_ playerID: String, tournamentService: TournamentServicing) async {
        guard let players = session?.players else { return }
        let onCourt = session?.currentRound.flatMap { $0.teamA + $0.teamB }.contains(playerID) ?? false
        guard !onCourt else { errorMessage = "Can't remove someone currently on court."; return }
        await pushPlayerUpdate(players.filter { $0.id != playerID }, tournamentService: tournamentService)
    }

    private func pushPlayerUpdate(_ players: [TournamentPlayer], tournamentService: TournamentServicing) async {
        guard let session else { return }
        do {
            self.session = try await tournamentService.updatePlayers(players, for: session)
        } catch {
            errorMessage = "Could not update players."
        }
    }
}
