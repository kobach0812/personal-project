import SwiftUI

struct TournamentView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = TournamentViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.session != nil {
                    TournamentActiveView(vm: vm)
                } else {
                    TournamentSetupView(vm: vm)
                }
            }
            .navigationTitle("Game")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .task {
            await vm.load(
                userProfileService: env.userProfileService,
                squadService: env.squadService,
                tournamentService: env.tournamentService
            )
        }
    }
}

// MARK: - Setup

struct TournamentSetupView: View {
    @ObservedObject var vm: TournamentViewModel
    @EnvironmentObject private var env: AppEnvironment
    @FocusState private var nameFieldFocused: Bool

    private var canStart: Bool { vm.setupPlayers.count >= 4 }

    private var footerText: String {
        let count = vm.setupPlayers.count
        let needed = vm.courts * 4
        if count < 4 { return "Add at least 4 players to start." }
        if count < needed { return "\(vm.courts) courts need \(needed) players — \(needed - count) more needed, or reduce courts." }
        // activeCourts = how many courts can actually run (floor(count/4), capped by requested courts)
        let activeCourts = min(vm.courts, count / 4)
        let playing = activeCourts * 4
        let sittingCount = count - playing
        return sittingCount > 0 ? "\(sittingCount) player(s) will sit out each round." : "All \(count) players will play every round."
    }

    var body: some View {
        Form {
            Section("Courts") {
                Stepper("\(vm.courts) court(s)", value: $vm.courts, in: 1...8)
            }

            Section {
                ForEach(vm.setupPlayers) { player in
                    Text(player.name)
                }
                .onDelete(perform: vm.removeSetupPlayer)

                HStack {
                    TextField("Player name", text: $vm.newPlayerName)
                        .focused($nameFieldFocused)
                        .onSubmit { vm.addSetupPlayer() }
                    Button("Add") { vm.addSetupPlayer() }
                        .disabled(vm.newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Players (\(vm.setupPlayers.count))")
            } footer: {
                Text(footerText)
                    .foregroundStyle(canStart ? Color.secondary : Color.orange)
            }

            Section {
                Button("Start Session") {
                    nameFieldFocused = false
                    Task { await vm.startSession(tournamentService: env.tournamentService) }
                }
                .frame(maxWidth: .infinity)
                .disabled(!canStart || vm.isLoading)
            }
        }
        .disabled(vm.isLoading)
    }
}

// MARK: - Active (Round / Board / History top tabs)

struct TournamentActiveView: View {
    @ObservedObject var vm: TournamentViewModel
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Round").tag(0)
                Text("Board").tag(1)
                Text("History").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            switch selectedTab {
            case 0: TournamentRoundView(vm: vm)
            case 1: TournamentBillboardView(vm: vm)
            default: TournamentHistoryView(vm: vm)
            }
        }
    }
}
