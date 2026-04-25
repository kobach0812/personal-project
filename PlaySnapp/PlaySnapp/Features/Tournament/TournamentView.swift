import Combine
import SwiftUI

// MARK: - Entry point (Game tab)

struct TournamentView: View {
    var body: some View {
        NavigationStack {
            TournamentListView()
        }
    }
}

// MARK: - Tournament list ViewModel

@MainActor
final class TournamentListViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var currentUser: AppUser?
    @Published var squad: Squad?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(
        userProfileService: UserProfileServicing,
        squadService: SquadServicing,
        tournamentService: TournamentServicing
    ) async {
        isLoading = true
        defer { isLoading = false }
        async let user         = try? userProfileService.fetchCurrentUser()
        async let fetchedSquad = try? squadService.fetchCurrentSquad()
        currentUser = await user
        squad       = await fetchedSquad
        guard let squadID = squad?.id else { return }
        do {
            tournaments = try await tournamentService.fetchTournaments(squadID: squadID)
        } catch {
            errorMessage = "Could not load tournaments."
        }
    }
}

// MARK: - Tournament list view

struct TournamentListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = TournamentListViewModel()
    @State private var showSetup = false
    @State private var navigateTo: Tournament?

    var body: some View {
        listContent
            .navigationTitle("Tournaments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSetup = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(item: $navigateTo) { (tournament: Tournament) in
                TournamentDetailView(
                    tournament: tournament,
                    currentUser: vm.currentUser,
                    squadMemberIDs: vm.squad?.memberIDs ?? []
                )
            }
            .sheet(isPresented: $showSetup) { setupSheet }
            .task { await loadTournaments() }
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
        } else if vm.tournaments.isEmpty {
            ContentUnavailableView(
                "No tournaments yet",
                systemImage: "sportscourt",
                description: Text("Tap + to create your first tournament.")
            )
        } else {
            List {
                ForEach(vm.tournaments) { tournament in
                    Button { navigateTo = tournament } label: {
                        TournamentRow(tournament: tournament)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var setupSheet: some View {
        TournamentSetupSheet(
            squadID: vm.squad?.id ?? "",
            createdBy: vm.currentUser?.id ?? "",
            squadMemberIDs: vm.squad?.memberIDs ?? []
        ) { (newTournament: Tournament) in
            vm.tournaments.insert(newTournament, at: 0)
        }
    }

    private func loadTournaments() async {
        await vm.load(
            userProfileService: env.userProfileService,
            squadService: env.squadService,
            tournamentService: env.tournamentService
        )
    }
}

// MARK: - Tournament row

private struct TournamentRow: View {
    let tournament: Tournament

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tournament.status == .active ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(tournament.title.isEmpty ? "Tournament" : tournament.title)
                    .font(.body)
                Text("\(tournament.players.count) players")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tournament.status == .active ? "Active" : "Finished")
                    .font(.caption.bold())
                    .foregroundStyle(tournament.status == .active ? .green : .secondary)
                if tournament.activeDayID != nil {
                    Text("Day in progress")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Tournament creation sheet

struct TournamentSetupSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let squadID: String
    let createdBy: String
    let squadMemberIDs: [String]
    var onCreated: (Tournament) -> Void

    @State private var title = ""
    @State private var players: [TournamentPlayer] = []
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
                    Button("Create Tournament") { Task { await create() } }
                        .frame(maxWidth: .infinity)
                        .disabled(!canCreate || isCreating)
                }
            }
            .disabled(isCreating)
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showPicker) {
                PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { (newPlayers: [TournamentPlayer]) in
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
            let tournament = try await env.tournamentService.createTournament(
                squadID: squadID,
                createdBy: createdBy,
                title: title.trimmingCharacters(in: .whitespaces),
                players: players
            )
            dismiss()
            onCreated(tournament)
        } catch {
            errorMessage = "Could not create tournament."
        }
    }
}

// MARK: - Active day view container (Summary / Round / Board / History)

struct TournamentActiveView: View {
    @ObservedObject var vm: TournamentViewModel
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
                    TournamentSummaryView(session: session)
                } else {
                    TournamentRoundView(vm: vm)
                }
            case 1:  TournamentBillboardView(players: vm.billboardPlayers)
            default: TournamentHistoryView(
                        matches: vm.session?.completedMatches ?? [],
                        playerName: vm.playerName
                     )
            }
        }
        .onChange(of: vm.session?.status) { old, new in
            if old == .active && new == .finished {
                selectedTab = 0 // switch to Summary when day ends
            }
        }
    }
}
