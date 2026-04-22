import Combine
import SwiftUI

@MainActor
final class TournamentViewModel: ObservableObject {
    @Published var session: TournamentSession?
    @Published var squad: Squad?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Setup form state
    @Published var courts = 2
    @Published var setupPlayers: [TournamentPlayer] = []
    @Published var newPlayerName = ""

    var isOrganizer: Bool {
        guard let session, let user = currentUser else { return false }
        return session.createdBy == user.id
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

    // MARK: - Actions

    func load(
        userProfileService: UserProfileServicing,
        squadService: SquadServicing,
        tournamentService: TournamentServicing
    ) async {
        isLoading = true
        defer { isLoading = false }
        async let user = try? userProfileService.fetchCurrentUser()
        async let squad = try? squadService.fetchCurrentSquad()
        currentUser = await user
        self.squad = await squad
        guard let squadID = self.squad?.id else { return }
        session = try? await tournamentService.fetchActiveSession(squadID: squadID)
    }

    func addSetupPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        setupPlayers.append(TournamentPlayer(id: UUID().uuidString, name: name, userID: nil, played: 0, wins: 0, losses: 0, lastPlayedAt: 0))
        newPlayerName = ""
    }

    func removeSetupPlayer(at offsets: IndexSet) {
        setupPlayers.remove(atOffsets: offsets)
    }

    func startSession(tournamentService: TournamentServicing) async {
        guard let squad, let user = currentUser else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            session = try await tournamentService.createSession(
                squadID: squad.id,
                createdBy: user.id,
                courts: courts,
                players: setupPlayers
            )
        } catch {
            errorMessage = "Could not start session."
        }
    }

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
            self.session = nil
            setupPlayers = []
            courts = 2
        } catch {
            errorMessage = "Could not end session."
        }
    }
}
