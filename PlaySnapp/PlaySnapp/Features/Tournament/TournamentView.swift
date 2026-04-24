import Combine
import SwiftUI

// MARK: - Entry point (Game tab)

struct TournamentView: View {
    var body: some View {
        NavigationStack {
            GameSessionListView()
        }
    }
}

// MARK: - Session list

@MainActor
final class GameSessionListViewModel: ObservableObject {
    @Published var sessions: [TournamentSession] = []
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
        async let user = try? userProfileService.fetchCurrentUser()
        async let fetchedSquad = try? squadService.fetchCurrentSquad()
        currentUser = await user
        squad = await fetchedSquad
        guard let squadID = squad?.id else { return }
        do {
            sessions = try await tournamentService.fetchSessions(squadID: squadID)
        } catch {
            errorMessage = "Could not load sessions."
        }
    }
}

struct GameSessionListView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = GameSessionListViewModel()
    @State private var showSetup = false
    @State private var navigateTo: TournamentSession?

    var body: some View {
        sessionContent
            .navigationTitle("Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSetup = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(item: $navigateTo) { (session: TournamentSession) in
                TournamentSessionView(session: session, currentUser: vm.currentUser)
            }
            .sheet(isPresented: $showSetup) { setupSheet }
            .task { await loadSessions() }
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
    private var sessionContent: some View {
        if vm.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.sessions.isEmpty {
            ContentUnavailableView(
                "No sessions yet",
                systemImage: "sportscourt",
                description: Text("Tap + to start a new session.")
            )
        } else {
            List {
                ForEach(vm.sessions) { session in
                    Button { navigateTo = session } label: { SessionRow(session: session) }
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
        ) { (newSession: TournamentSession) in
            vm.sessions.insert(newSession, at: 0)
        }
    }

    private func loadSessions() async {
        await vm.load(
            userProfileService: env.userProfileService,
            squadService: env.squadService,
            tournamentService: env.tournamentService
        )
    }
}

private struct SessionRow: View {
    let session: TournamentSession

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.status == .active ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title.isEmpty ? "Session" : session.title)
                    .font(.body)
                Text("\(session.players.count) players · \(session.courts) court(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(session.status == .active ? "Active" : "Finished")
                .font(.caption.bold())
                .foregroundStyle(session.status == .active ? .green : .secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Session container (wraps TournamentViewModel for one session)

struct TournamentSessionView: View {
    let session: TournamentSession
    let currentUser: AppUser?
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = TournamentViewModel()
    @Environment(\.dismiss) private var dismiss

    private var navTitle: String {
        session.title.isEmpty ? "Session" : session.title
    }

    var body: some View {
        TournamentActiveView(vm: vm)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.loadSession(
                    session,
                    currentUser: currentUser,
                    tournamentService: env.tournamentService
                )
            }
            .onChange(of: vm.session?.status) { old, new in
                // Only auto-dismiss on the active → finished transition (user just ended it).
                // Opening an already-finished session goes nil → .finished, which we want to allow.
                if old == .active && new == .finished { dismiss() }
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
    }
}

// MARK: - Setup sheet

struct TournamentSetupSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let squadID: String
    let createdBy: String
    let squadMemberIDs: [String]
    var onSessionCreated: (TournamentSession) -> Void

    @State private var title = ""
    @State private var courts = 2
    @State private var players: [TournamentPlayer] = []
    @State private var showPicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var canStart: Bool { players.count >= 4 }

    private var footerText: String {
        let count = players.count
        let needed = courts * 4
        if count < 4 { return "Add at least 4 players to start." }
        if count < needed { return "\(courts) courts need \(needed) players — \(needed - count) more needed, or reduce courts." }
        let activeCourts = min(courts, count / 4)
        let playing = activeCourts * 4
        let sittingCount = count - playing
        return sittingCount > 0
            ? "\(sittingCount) player(s) will sit out each round."
            : "All \(count) players will play every round."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Name (optional, e.g. Tuesday 8pm)", text: $title)
                }

                Section("Courts") {
                    Stepper("\(courts) court(s)", value: $courts, in: 1...8)
                }

                Section {
                    ForEach(players) { player in
                        Text(player.name)
                    }
                    .onDelete { players.remove(atOffsets: $0) }

                    Button {
                        showPicker = true
                    } label: {
                        Label("Add Players", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Players (\(players.count))")
                } footer: {
                    Text(footerText)
                        .foregroundStyle(canStart ? Color.secondary : Color.orange)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section {
                    Button("Start Session") {
                        Task { await start() }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!canStart || isCreating)
                }
            }
            .disabled(isCreating)
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { newPlayers in
                    // Merge: skip players already in the roster by userID or name
                    let existingUserIDs = Set(players.compactMap(\.userID))
                    let existingNames = Set(players.filter { $0.userID == nil }.map(\.name))
                    for p in newPlayers {
                        if let uid = p.userID {
                            if !existingUserIDs.contains(uid) { players.append(p) }
                        } else {
                            if !existingNames.contains(p.name) { players.append(p) }
                        }
                    }
                }
            }
        }
    }

    private func start() async {
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            let session = try await env.tournamentService.createSession(
                squadID: squadID,
                createdBy: createdBy,
                title: title.trimmingCharacters(in: .whitespaces),
                courts: courts,
                players: players
            )
            dismiss()
            onSessionCreated(session)
        } catch {
            errorMessage = "Could not start session."
        }
    }
}

// MARK: - Active session (Round / Board / History tabs)

struct TournamentActiveView: View {
    @ObservedObject var vm: TournamentViewModel
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Participant banner: shown when the current user is up on a court
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
                Text("Round").tag(0)
                Text("Board").tag(1)
                Text("History").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            switch selectedTab {
            case 0:  TournamentRoundView(vm: vm)
            case 1:  TournamentBillboardView(vm: vm)
            default: TournamentHistoryView(vm: vm)
            }
        }
    }
}
