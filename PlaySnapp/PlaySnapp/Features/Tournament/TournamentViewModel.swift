import Combine
import SwiftUI

@MainActor
final class TournamentViewModel: ObservableObject {
    @Published var session: TournamentSession?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isOrganizer: Bool {
        guard let session, let user = currentUser else { return false }
        return session.createdBy == user.id
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
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            if $0.losses != $1.losses { return $0.losses < $1.losses }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var sittingOut: [TournamentPlayer] {
        guard let session else { return [] }
        let activeIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        return session.players.filter { !activeIDs.contains($0.id) }
    }

    func playerName(_ id: String) -> String {
        session?.players.first { $0.id == id }?.name ?? id
    }

    // MARK: - Session Loading

    /// Initialise the VM with a specific session and fetch its completed matches.
    func loadSession(_ session: TournamentSession, currentUser: AppUser?, tournamentService: TournamentServicing) async {
        self.session = session
        self.currentUser = currentUser
        if let matches = try? await tournamentService.fetchMatches(squadID: session.squadID, sessionID: session.id) {
            self.session?.completedMatches = matches
        }
    }

    // MARK: - Actions

    func recordResult(matchID: String, winner: WinnerTeam, scoreA: Int?, scoreB: Int?, tournamentService: TournamentServicing) async {
        guard let session else { return }
        do {
            self.session = try await tournamentService.recordResult(for: session, matchID: matchID, winner: winner, scoreA: scoreA, scoreB: scoreB)
        } catch {
            errorMessage = "Could not save result."
        }
    }

    func endSession(tournamentService: TournamentServicing) async {
        guard let session else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await tournamentService.endSession(session)
            self.session?.status = .finished
        } catch {
            errorMessage = "Could not end session."
        }
    }
}
