import SwiftUI

struct TournamentRoundView: View {
    @ObservedObject var vm: TournamentViewModel
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let session = vm.session {
                    ForEach(session.currentRound.sorted { $0.court < $1.court }) { match in
                        MatchCard(match: match, vm: vm)
                    }

                    if !vm.sittingOut.isEmpty || !vm.benched.isEmpty {
                        PlayerStatusCard(vm: vm)
                    }

                    if vm.isOrganizer && session.status == .active {
                        Button("End Day") {
                            Task { await vm.endDay(tournamentService: env.tournamentService) }
                        }
                        .foregroundStyle(.red)
                        .padding(.bottom)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: TournamentMatch
    @ObservedObject var vm: TournamentViewModel
    @EnvironmentObject private var env: AppEnvironment
    @State private var showResultSheet = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Court \(match.court)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 0) {
                teamColumn(ids: match.teamA, isWinner: match.winnerTeam == .teamA)
                Text("vs").foregroundStyle(.secondary).frame(width: 36)
                teamColumn(ids: match.teamB, isWinner: match.winnerTeam == .teamB)
            }

            if vm.isOrganizer && match.winnerTeam == nil {
                Button("Enter Result") { showResultSheet = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else if let winner = match.winnerTeam {
                Label(winner == .teamA ? "Team A wins" : "Team B wins", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal)
        .sheet(isPresented: $showResultSheet) {
            ResultEntrySheet(match: match, vm: vm).environmentObject(env)
        }
    }

    @ViewBuilder
    private func teamColumn(ids: [String], isWinner: Bool) -> some View {
        VStack(spacing: 4) {
            ForEach(ids, id: \.self) { id in
                Text(vm.playerName(id))
                    .font(isWinner ? .callout.bold() : .callout)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Result Entry Sheet

struct ResultEntrySheet: View {
    let match: TournamentMatch
    @ObservedObject var vm: TournamentViewModel
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var scoreAText = ""
    @State private var scoreBText = ""
    @State private var selectedWinner: WinnerTeam?

    private var inferredWinner: WinnerTeam? {
        guard let a = Int(scoreAText), let b = Int(scoreBText), a != b else { return nil }
        return a > b ? .teamA : .teamB
    }

    private var effectiveWinner: WinnerTeam? { selectedWinner ?? inferredWinner }
    private var canSubmit: Bool { effectiveWinner != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Score") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Team A").font(.caption).foregroundStyle(.secondary)
                            TextField("0", text: $scoreAText)
                                .keyboardType(.numberPad)
                                .onChange(of: scoreAText) { _, _ in selectedWinner = nil }
                        }
                        Spacer()
                        Text("vs").foregroundStyle(.secondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Team B").font(.caption).foregroundStyle(.secondary)
                            TextField("0", text: $scoreBText)
                                .keyboardType(.numberPad)
                                .onChange(of: scoreBText) { _, _ in selectedWinner = nil }
                        }
                    }
                }
                Section("Winner") {
                    winnerButton(.teamA)
                    winnerButton(.teamB)
                }
            }
            .navigationTitle("Court \(match.court) Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let winner = effectiveWinner else { return }
                        let a = Int(scoreAText), b = Int(scoreBText)
                        dismiss()
                        Task {
                            await vm.recordResult(
                                matchID: match.id, winner: winner,
                                scoreA: a, scoreB: b,
                                tournamentService: env.tournamentService
                            )
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private func winnerButton(_ team: WinnerTeam) -> some View {
        let ids = team == .teamA ? match.teamA : match.teamB
        let label = ids.map { vm.playerName($0) }.joined(separator: " & ")
        return Button { selectedWinner = team } label: {
            HStack {
                Text(label)
                Spacer()
                if effectiveWinner == team {
                    Image(systemName: "checkmark").foregroundStyle(.blue)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Player Status Card (sitting out + benched)

struct PlayerStatusCard: View {
    @ObservedObject var vm: TournamentViewModel
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.sittingOut.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sitting out")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(vm.sittingOut) { player in
                        HStack {
                            Text(player.name).font(.callout)
                            Spacer()
                            if vm.isOrganizer {
                                Menu {
                                    Button("Bench (skip rotation)") {
                                        Task { await vm.benchPlayer(player.id, tournamentService: env.tournamentService) }
                                    }
                                    Button("Remove from day", role: .destructive) {
                                        Task { await vm.removePlayer(player.id, tournamentService: env.tournamentService) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if !vm.benched.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Benched")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    ForEach(vm.benched) { player in
                        HStack {
                            Text(player.name).font(.callout).foregroundStyle(.secondary)
                            Spacer()
                            if vm.isOrganizer {
                                Menu {
                                    Button("Restore to rotation") {
                                        Task { await vm.restorePlayer(player.id, tournamentService: env.tournamentService) }
                                    }
                                    Button("Remove from day", role: .destructive) {
                                        Task { await vm.removePlayer(player.id, tournamentService: env.tournamentService) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
