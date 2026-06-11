import SwiftUI

// MARK: - GameDetailView (Board + Days tabs)

struct GameDetailView: View {
    @EnvironmentObject private var env: AppEnvironment

    let initialGame: Game
    let currentUser: AppUser?
    let squadMemberIDs: [String]

    @State private var game: Game
    @State private var sessions: [GameSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var showStartDay = false
    @State private var showScheduleDay = false
    @State private var showAddPlayers = false
    @State private var showEndConfirm = false
    @State private var navigateToSession: GameSession?

    private var isOrganizer: Bool { game.createdBy == (currentUser?.id ?? "") }
    private var hasActiveDay: Bool { game.activeDayID != nil }
    /// Organizer can manage the roster + create days only while the game is active.
    private var canManageRoster: Bool { isOrganizer && game.status == .active }

    /// Board-tab delete handler — nil for non-organizers (hides the "Remove" action).
    private var boardRemoveHandler: ((GamePlayer) -> Void)? {
        guard canManageRoster else { return nil }
        return { player in Task { await removePlayer(player) } }
    }

    init(game: Game, currentUser: AppUser?, squadMemberIDs: [String]) {
        self.initialGame = game
        self.currentUser = currentUser
        self.squadMemberIDs = squadMemberIDs
        _game = State(initialValue: game)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Board").tag(0)
                Text("Days").tag(1)
                Text("Tournaments").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            switch selectedTab {
            case 0:  GameBillboardView(players: game.players, onRemove: boardRemoveHandler)
            case 1:  daysListView
            default: BracketListView(game: game, currentUser: currentUser)
            }
        }
        .navigationTitle(game.title.isEmpty ? "Game" : game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOrganizer && game.status == .active {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showAddPlayers = true } label: {
                            Label("Add Players", systemImage: "person.badge.plus")
                        }
                        Divider()
                        Button(role: .destructive) { showEndConfirm = true } label: {
                            Label("End Game", systemImage: "flag.checkered")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .navigationDestination(item: $navigateToSession) { session in
            sessionDestination(for: session)
        }
        .sheet(isPresented: $showStartDay) {
            StartDaySheet(
                game: game,
                squadMemberIDs: squadMemberIDs
            ) { newGame, newSession in
                self.game = newGame
                self.sessions.append(newSession)
                self.navigateToSession = newSession
            }
        }
        .sheet(isPresented: $showScheduleDay) {
            ScheduleGameDaySheet(game: game) { newSession in
                sessions.append(newSession)
            }
        }
        .sheet(isPresented: $showAddPlayers) {
            PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { newPlayers in
                Task { await addPlayers(newPlayers) }
            }
        }
        .confirmationDialog("End Game?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Game", role: .destructive) {
                Task { await endGame() }
            }
        } message: {
            Text("The game will be marked as finished. This cannot be undone.")
        }
        .task { await loadSessions() }
        .onChange(of: navigateToSession) { old, new in
            // Reload sessions when returning from a day view
            if new == nil && old != nil {
                Task { await loadSessions() }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Session destination router

    @ViewBuilder
    private func sessionDestination(for session: GameSession) -> some View {
        switch session.status {
        case .scheduled, .cancelled:
            ScheduledDayDetailView(
                session: session,
                currentUser: currentUser,
                squadMemberIDs: squadMemberIDs
            ) { activeSession in
                // Replace the scheduled session with the now-active one
                if let idx = sessions.firstIndex(where: { $0.id == activeSession.id }) {
                    sessions[idx] = activeSession
                }
                navigateToSession = activeSession
            }
        case .active, .finished:
            DayDetailView(
                session: session,
                game: game,
                currentUser: currentUser,
                onGameUpdated: { self.game = $0 }
            )
        }
    }

    // MARK: - Days list

    @ViewBuilder
    private var daysListView: some View {
        VStack(spacing: 0) {
            if canManageRoster {
                dayCreateBar
                Divider()
            }
            daysContent
        }
    }

    /// Organizer buttons to start or schedule a play day — moved here from the ⋯ menu.
    private var dayCreateBar: some View {
        HStack(spacing: 12) {
            if !hasActiveDay {
                Button { showStartDay = true } label: {
                    Label("Walk-up Day", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Button { showScheduleDay = true } label: {
                Label("Schedule", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var daysContent: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if sessions.isEmpty {
            ContentUnavailableView(
                "No days yet",
                systemImage: "calendar.badge.plus",
                description: Text(isOrganizer
                    ? "Start or schedule a play day using the buttons above."
                    : "No play days have been recorded yet.")
            )
        } else {
            List {
                ForEach(sessions.sorted { lhs, rhs in
                    // Scheduled future days first, then by date desc
                    let lIsUpcoming = lhs.status == .scheduled
                    let rIsUpcoming = rhs.status == .scheduled
                    if lIsUpcoming != rIsUpcoming { return lIsUpcoming }
                    return lhs.createdAt > rhs.createdAt
                }) { session in
                    Button { navigateToSession = session } label: {
                        DayRow(session: session)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        if let loaded = try? await env.gameService.fetchSessions(for: game) {
            sessions = loaded
        }
    }

    private func addPlayers(_ newPlayers: [GamePlayer]) async {
        do {
            game = try await env.gameService.addPlayers(newPlayers, to: game)
        } catch {
            errorMessage = "Could not add players."
        }
    }

    private func removePlayer(_ player: GamePlayer) async {
        do {
            game = try await env.gameService.removePlayer(playerID: player.id, from: game)
        } catch {
            errorMessage = "Could not remove \(player.name)."
        }
    }

    private func endGame() async {
        do {
            try await env.gameService.endGame(game)
            game.status = .finished
            game.activeDayID = nil
        } catch {
            errorMessage = "Could not end game."
        }
    }
}

// MARK: - Day row

private struct DayRow: View {
    let session: GameSession

    private var statusLabel: String {
        switch session.status {
        case .scheduled:  return "Scheduled"
        case .active:     return "In progress"
        case .finished:   return "Finished"
        case .cancelled:  return "Cancelled"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .scheduled:  return .orange
        case .active:     return .green
        case .finished:   return .secondary
        case .cancelled:  return .red
        }
    }

    private var dateLabel: String {
        if session.status == .scheduled, let start = session.scheduledStart {
            return start.formatted(date: .abbreviated, time: .shortened)
        }
        return session.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title.isEmpty ? "Day" : session.title)
                    .font(.body)
                Text(dateLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let loc = session.location {
                    Text(loc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(statusLabel)
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)
                if session.status != .scheduled {
                    Text("\(session.players.count) players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Day detail view

struct DayDetailView: View {
    @EnvironmentObject private var env: AppEnvironment

    let initialSession: GameSession
    let initialGame: Game
    let currentUser: AppUser?
    var onGameUpdated: (Game) -> Void

    @StateObject private var vm = GameViewModel()

    init(
        session: GameSession,
        game: Game,
        currentUser: AppUser?,
        onGameUpdated: @escaping (Game) -> Void
    ) {
        self.initialSession = session
        self.initialGame = game
        self.currentUser = currentUser
        self.onGameUpdated = onGameUpdated
    }

    var body: some View {
        GameActiveView(vm: vm)
            .navigationTitle(initialSession.title.isEmpty ? "Day" : initialSession.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.loadDay(
                    initialSession,
                    game: initialGame,
                    currentUser: currentUser,
                    gameService: env.gameService
                )
            }
            .onChange(of: vm.game) { _, newGame in
                if let t = newGame { onGameUpdated(t) }
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .sheet(item: $vm.dayRecap) { recap in
                GameDayRecapSheet(recap: recap)
            }
    }
}

// MARK: - Start Day Sheet

struct StartDaySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let game: Game
    let squadMemberIDs: [String]
    var onStarted: (Game, GameSession) -> Void

    @State private var courts = 1
    @State private var sessionMode: SessionMode = .rotation
    @State private var draftFixedTeams: [FixedTeam] = []
    @State private var showTeamSetup = false
    /// Mutable local copy of the game roster — guest names can be edited inline.
    @State private var rosterPlayers: [GamePlayer]
    @State private var selectedPlayerIDs: Set<String>
    @State private var isStarting = false
    @State private var errorMessage: String?

    init(
        game: Game,
        squadMemberIDs: [String],
        onStarted: @escaping (Game, GameSession) -> Void
    ) {
        self.game = game
        self.squadMemberIDs = squadMemberIDs
        self.onStarted = onStarted
        _rosterPlayers = State(initialValue: game.players)
        _selectedPlayerIDs = State(initialValue: Set(game.players.map(\.id)))
    }

    private var allPlayers: [GamePlayer] { rosterPlayers }

    private var selectedPlayers: [GamePlayer] {
        allPlayers.filter { selectedPlayerIDs.contains($0.id) }
    }

    private var canStart: Bool {
        if sessionMode == .fixedTeams {
            return draftFixedTeams.count >= 2 && draftFixedTeams.allSatisfy { $0.playerIDs.count == 2 }
        }
        return selectedPlayers.count >= courts * 4
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Courts") {
                    Stepper("Courts: \(courts)", value: $courts, in: 1...4)
                }

                Section("Session Mode") {
                    Picker("Mode", selection: $sessionMode) {
                        Text("Rotation").tag(SessionMode.rotation)
                        Text("Fixed Teams").tag(SessionMode.fixedTeams)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: sessionMode) { _, _ in
                        // Clear draft teams when switching back to rotation
                        if sessionMode == .rotation { draftFixedTeams = [] }
                    }

                    if sessionMode == .fixedTeams {
                        Button {
                            showTeamSetup = true
                        } label: {
                            HStack {
                                Label(draftFixedTeams.isEmpty ? "Set Up Teams" : "Edit Teams",
                                      systemImage: "person.2.badge.gearshape")
                                Spacer()
                                if !draftFixedTeams.isEmpty {
                                    Text("\(draftFixedTeams.count) teams")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Summary of configured teams
                        ForEach(draftFixedTeams) { team in
                            let names = team.playerIDs
                                .compactMap { id in allPlayers.first { $0.id == id }?.name }
                                .joined(separator: " & ")
                            HStack {
                                Text(team.name).font(.callout.bold())
                                Text(names).font(.callout).foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section {
                    // Roster players — pick who's playing today. Add/remove players
                    // from the game via the ⋯ menu on the game screen.
                    ForEach($rosterPlayers) { $player in
                        PlayerToggleRow(
                            player: $player,
                            isSelected: selectedPlayerIDs.contains(player.id),
                            onToggle: { on in
                                if on { selectedPlayerIDs.insert(player.id) }
                                else  { selectedPlayerIDs.remove(player.id) }
                            }
                        )
                    }
                } header: {
                    Text("Today's Players (\(selectedPlayers.count))")
                } footer: {
                    if !canStart {
                        if sessionMode == .fixedTeams {
                            Text("Set up at least 2 complete teams to start.")
                                .foregroundStyle(.red)
                        } else {
                            Text("Need at least \(courts * 4) players for \(courts) court(s).")
                                .foregroundStyle(.red)
                        }
                    }
                }

                if let error = errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }

                Section {
                    Button("Start Day") { Task { await startDay() } }
                        .frame(maxWidth: .infinity)
                        .disabled(!canStart || isStarting)
                }
            }
            .disabled(isStarting)
            .navigationTitle("Start New Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showTeamSetup) {
                FixedTeamSetupSheet(
                    players: selectedPlayers,
                    initialTeams: draftFixedTeams
                ) { teams in
                    draftFixedTeams = teams
                }
            }
        }
    }

    private func startDay() async {
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }

        // Full roster after edits: updated names + any newly added players
        let finalRoster = rosterPlayers

        // Today's players: selected subset, daily stats reset
        let dayPlayers = selectedPlayers.map { p in
            GamePlayer(
                id: p.id, name: p.name, userID: p.userID,
                played: 0, wins: 0, losses: 0, lastPlayedAt: 0,
                isActive: true
            )
        }

        do {
            // Persist roster changes (renamed guests + new additions) before starting the day
            let updatedGame = try await env.gameService.setGameRoster(
                finalRoster, for: game
            )
            let (newGame, session) = try await env.gameService.startDay(
                for: updatedGame, courts: courts, players: dayPlayers,
                mode: sessionMode, fixedTeams: draftFixedTeams
            )
            dismiss()
            onStarted(newGame, session)
        } catch {
            errorMessage = "Could not start day."
        }
    }
}

// MARK: - Player toggle row (used in StartDaySheet)

struct PlayerToggleRow: View {
    @Binding var player: GamePlayer
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            if player.userID == nil {
                // Guest — editable name
                TextField("Name", text: $player.name)
            } else {
                Text(player.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle("", isOn: Binding(get: { isSelected }, set: { onToggle($0) }))
                .labelsHidden()
        }
    }
}
