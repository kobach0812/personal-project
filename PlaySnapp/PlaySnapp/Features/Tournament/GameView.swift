import Combine
import SwiftUI

// MARK: - Entry point (Game tab)

struct GameView: View {
    var body: some View {
        NavigationStack {
            GameListView()
        }
    }
}

// MARK: - Game list ViewModel

@MainActor
final class GameListViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var currentUser: AppUser?
    @Published var squad: Squad?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(
        userProfileService: UserProfileServicing,
        squadService: SquadServicing,
        gameService: GameServicing
    ) async {
        isLoading = true
        defer { isLoading = false }
        async let user         = try? userProfileService.fetchCurrentUser()
        async let fetchedSquad = try? squadService.fetchCurrentSquad()
        currentUser = await user
        squad       = await fetchedSquad
        guard let squadID = squad?.id else { return }
        do {
            games = try await gameService.fetchGames(squadID: squadID)
        } catch {
            errorMessage = "Could not load games."
        }
    }
}

// MARK: - Game list view

struct GameListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = GameListViewModel()
    @State private var showSetup = false
    @State private var navigateTo: Game?

    var body: some View {
        listContent
            .navigationTitle("Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSetup = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(item: $navigateTo) { (game: Game) in
                GameDetailView(
                    game: game,
                    currentUser: vm.currentUser,
                    squadMemberIDs: vm.squad?.memberIDs ?? []
                )
            }
            .sheet(isPresented: $showSetup) { setupSheet }
            .task { await loadGames() }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var listContent: some View {
        if vm.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.games.isEmpty {
            ContentUnavailableView(
                "No games yet",
                systemImage: "sportscourt",
                description: Text("Tap + to create your first game.")
            )
        } else {
            List {
                ForEach(vm.games) { game in
                    Button { navigateTo = game } label: {
                        GameRow(game: game)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var setupSheet: some View {
        GameSetupSheet(
            squadID: vm.squad?.id ?? "",
            createdBy: vm.currentUser?.id ?? "",
            squadMemberIDs: vm.squad?.memberIDs ?? []
        ) { (newGame: Game) in
            vm.games.insert(newGame, at: 0)
        }
    }

    private func loadGames() async {
        await vm.load(
            userProfileService: env.userProfileService,
            squadService: env.squadService,
            gameService: env.gameService
        )
    }
}

// MARK: - Game row

private struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(game.status == .active ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(game.title.isEmpty ? "Game" : game.title)
                    .font(.body)
                Text("\(game.players.count) players")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(game.status == .active ? "Active" : "Finished")
                    .font(.caption.bold())
                    .foregroundStyle(game.status == .active ? .green : .secondary)
                if game.activeDayID != nil {
                    Text("Day in progress")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Game creation sheet

struct GameSetupSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let squadID: String
    let createdBy: String
    let squadMemberIDs: [String]
    var onCreated: (Game) -> Void

    @State private var title = ""
    @State private var players: [GamePlayer] = []
    @State private var showPicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var canCreate: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Tuesday Badminton League", text: $title)
                }

                Section {
                    ForEach(players) { player in Text(player.name) }
                        .onDelete { players.remove(atOffsets: $0) }
                    Button { showPicker = true } label: {
                        Label("Add Players", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Initial Roster (\(players.count))")
                } footer: {
                    Text("You can adjust who plays on each day.")
                        .foregroundStyle(.secondary)
                }

                if let error = errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }

                Section {
                    Button("Create Game") { Task { await create() } }
                        .frame(maxWidth: .infinity)
                        .disabled(!canCreate || isCreating)
                }
            }
            .disabled(isCreating)
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showPicker) {
                PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { (newPlayers: [GamePlayer]) in
                    let existingIDs   = Set(players.compactMap(\.userID))
                    let existingNames = Set(players.filter { $0.userID == nil }.map(\.name))
                    for p in newPlayers {
                        if let uid = p.userID { if !existingIDs.contains(uid)     { players.append(p) } }
                        else                  { if !existingNames.contains(p.name) { players.append(p) } }
                    }
                }
            }
        }
    }

    private func create() async {
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            let game = try await env.gameService.createGame(
                squadID: squadID,
                createdBy: createdBy,
                title: title.trimmingCharacters(in: .whitespaces),
                players: players
            )
            dismiss()
            onCreated(game)
        } catch {
            errorMessage = "Could not create game."
        }
    }
}

// MARK: - Active day view container (Summary / Round / Board / History)

struct GameActiveView: View {
    @ObservedObject var vm: GameViewModel
    @State private var selectedTab = 0

    private var isFinished: Bool { vm.session?.status == .finished }

    var body: some View {
        VStack(spacing: 0) {
            if let banner = vm.participantBannerText {
                Text(banner)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            Picker("", selection: $selectedTab) {
                Text(isFinished ? "Summary" : "Round").tag(0)
                Text("Board").tag(1)
                Text("History").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            switch selectedTab {
            case 0:
                if isFinished, let session = vm.session {
                    GameSummaryView(session: session)
                } else {
                    GameRoundView(vm: vm)
                }
            case 1:  GameBillboardView(players: vm.billboardPlayers)
            default: GameHistoryView(
                        matches: vm.session?.completedMatches ?? [],
                        playerName: vm.playerName
                     )
            }
        }
        .onChange(of: vm.session?.status) { old, new in
            if old == .active && new == .finished {
                selectedTab = 0
            }
        }
    }
}
