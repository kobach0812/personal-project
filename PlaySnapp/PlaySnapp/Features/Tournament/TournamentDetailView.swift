import SwiftUI

// MARK: - TournamentDetailView (Board + Days tabs)

struct TournamentDetailView: View {
    @EnvironmentObject private var env: AppEnvironment

    let initialTournament: Tournament
    let currentUser: AppUser?
    let squadMemberIDs: [String]

    @State private var tournament: Tournament
    @State private var sessions: [TournamentSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var showStartDay = false
    @State private var showScheduleDay = false
    @State private var showEndConfirm = false
    @State private var navigateToSession: TournamentSession?

    private var isOrganizer: Bool { tournament.createdBy == (currentUser?.id ?? "") }
    private var hasActiveDay: Bool { tournament.activeDayID != nil }

    init(tournament: Tournament, currentUser: AppUser?, squadMemberIDs: [String]) {
        self.initialTournament = tournament
        self.currentUser = currentUser
        self.squadMemberIDs = squadMemberIDs
        _tournament = State(initialValue: tournament)
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
            case 0:  TournamentBillboardView(players: tournament.players)
            case 1:  daysListView
            default: BracketListView(tournament: tournament, currentUser: currentUser)
            }
        }
        .navigationTitle(tournament.title.isEmpty ? "Tournament" : tournament.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOrganizer && tournament.status == .active {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if !hasActiveDay {
                            Button { showStartDay = true } label: {
                                Label("Start Walk-up Day", systemImage: "play.circle")
                            }
                        }
                        Button { showScheduleDay = true } label: {
                            Label("Schedule Game Day", systemImage: "calendar.badge.plus")
                        }
                        Divider()
                        Button(role: .destructive) { showEndConfirm = true } label: {
                            Label("End Tournament", systemImage: "flag.checkered")
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
                tournament: tournament,
                squadMemberIDs: squadMemberIDs
            ) { newTournament, newSession in
                self.tournament = newTournament
                self.sessions.append(newSession)
                self.navigateToSession = newSession
            }
        }
        .sheet(isPresented: $showScheduleDay) {
            ScheduleGameDaySheet(tournament: tournament) { newSession in
                sessions.append(newSession)
            }
        }
        .confirmationDialog("End Tournament?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Tournament", role: .destructive) {
                Task { await endTournament() }
            }
        } message: {
            Text("The tournament will be marked as finished. This cannot be undone.")
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
    private func sessionDestination(for session: TournamentSession) -> some View {
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
                tournament: tournament,
                currentUser: currentUser,
                onTournamentUpdated: { self.tournament = $0 }
            )
        }
    }

    // MARK: - Days list

    @ViewBuilder
    private var daysListView: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if sessions.isEmpty {
            ContentUnavailableView(
                "No days yet",
                systemImage: "calendar.badge.plus",
                description: Text(isOrganizer
                    ? "Tap ⋯ to start or schedule a play day."
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
        if let loaded = try? await env.tournamentService.fetchSessions(for: tournament) {
            sessions = loaded
        }
    }

    private func endTournament() async {
        do {
            try await env.tournamentService.endTournament(tournament)
            tournament.status = .finished
            tournament.activeDayID = nil
        } catch {
            errorMessage = "Could not end tournament."
        }
    }
}

// MARK: - Day row

private struct DayRow: View {
    let session: TournamentSession

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

    let initialSession: TournamentSession
    let initialTournament: Tournament
    let currentUser: AppUser?
    var onTournamentUpdated: (Tournament) -> Void

    @StateObject private var vm = TournamentViewModel()

    init(
        session: TournamentSession,
        tournament: Tournament,
        currentUser: AppUser?,
        onTournamentUpdated: @escaping (Tournament) -> Void
    ) {
        self.initialSession = session
        self.initialTournament = tournament
        self.currentUser = currentUser
        self.onTournamentUpdated = onTournamentUpdated
    }

    var body: some View {
        TournamentActiveView(vm: vm)
            .navigationTitle(initialSession.title.isEmpty ? "Day" : initialSession.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.loadDay(
                    initialSession,
                    tournament: initialTournament,
                    currentUser: currentUser,
                    tournamentService: env.tournamentService
                )
            }
            .onChange(of: vm.tournament) { _, newTournament in
                if let t = newTournament { onTournamentUpdated(t) }
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

// MARK: - Start Day Sheet

struct StartDaySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let tournament: Tournament
    let squadMemberIDs: [String]
    var onStarted: (Tournament, TournamentSession) -> Void

    @State private var courts = 1
    @State private var sessionMode: SessionMode = .rotation
    @State private var draftFixedTeams: [FixedTeam] = []
    @State private var showTeamSetup = false
    /// Mutable local copy of the tournament roster — guest names can be edited inline.
    @State private var rosterPlayers: [TournamentPlayer]
    /// Players added this session via PlayerPickerSheet (not yet on the tournament roster).
    @State private var extraPlayers: [TournamentPlayer] = []
    @State private var selectedPlayerIDs: Set<String>
    @State private var showPicker = false
    @State private var isStarting = false
    @State private var errorMessage: String?

    init(
        tournament: Tournament,
        squadMemberIDs: [String],
        onStarted: @escaping (Tournament, TournamentSession) -> Void
    ) {
        self.tournament = tournament
        self.squadMemberIDs = squadMemberIDs
        self.onStarted = onStarted
        _rosterPlayers = State(initialValue: tournament.players)
        _selectedPlayerIDs = State(initialValue: Set(tournament.players.map(\.id)))
    }

    private var allPlayers: [TournamentPlayer] { rosterPlayers + extraPlayers }

    private var selectedPlayers: [TournamentPlayer] {
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
                    // Existing roster — guests get an editable name field
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
                    // Newly added players (all treated as guests until persisted)
                    ForEach($extraPlayers) { $player in
                        PlayerToggleRow(
                            player: $player,
                            isSelected: selectedPlayerIDs.contains(player.id),
                            onToggle: { on in
                                if on { selectedPlayerIDs.insert(player.id) }
                                else  { selectedPlayerIDs.remove(player.id) }
                            }
                        )
                    }
                    Button { showPicker = true } label: {
                        Label("Add More Players", systemImage: "person.badge.plus")
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
            .sheet(isPresented: $showPicker) {
                PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { newPlayers in
                    // Dedup against the current full roster
                    let existingUserIDs = Set(allPlayers.compactMap(\.userID))
                    let existingNames   = Set(allPlayers.filter { $0.userID == nil }.map(\.name))
                    for p in newPlayers {
                        if let uid = p.userID {
                            if !existingUserIDs.contains(uid) {
                                extraPlayers.append(p)
                                selectedPlayerIDs.insert(p.id)
                            }
                        } else {
                            if !existingNames.contains(p.name) {
                                extraPlayers.append(p)
                                selectedPlayerIDs.insert(p.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private func startDay() async {
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }

        // Full roster after edits: updated names + any newly added players
        let finalRoster = rosterPlayers + extraPlayers

        // Today's players: selected subset, daily stats reset
        let dayPlayers = selectedPlayers.map { p in
            TournamentPlayer(
                id: p.id, name: p.name, userID: p.userID,
                played: 0, wins: 0, losses: 0, lastPlayedAt: 0,
                isActive: true
            )
        }

        do {
            // Persist roster changes (renamed guests + new additions) before starting the day
            let updatedTournament = try await env.tournamentService.setTournamentRoster(
                finalRoster, for: tournament
            )
            let (newTournament, session) = try await env.tournamentService.startDay(
                for: updatedTournament, courts: courts, players: dayPlayers,
                mode: sessionMode, fixedTeams: draftFixedTeams
            )
            dismiss()
            onStarted(newTournament, session)
        } catch {
            errorMessage = "Could not start day."
        }
    }
}

// MARK: - Player toggle row (used in StartDaySheet)

struct PlayerToggleRow: View {
    @Binding var player: TournamentPlayer
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
