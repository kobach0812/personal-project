import Combine
import SwiftUI

// MARK: - ViewModel

@MainActor
final class ScheduledDayViewModel: ObservableObject {
    @Published var session: TournamentSession
    @Published var registrations: [Registration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var observerTask: Task<Void, Never>?
    let currentUser: AppUser?
    let squadMemberIDs: [String]

    init(session: TournamentSession, currentUser: AppUser?, squadMemberIDs: [String]) {
        self.session = session
        self.currentUser = currentUser
        self.squadMemberIDs = squadMemberIDs
    }

    var isHost: Bool { session.createdBy == currentUser?.id }

    var myRegistration: Registration? {
        guard let uid = currentUser?.id else { return nil }
        return registrations.first { $0.userID == uid }
    }

    var checkedInCount: Int { registrations.filter { $0.checkedInAt != nil }.count }
    var yesCount: Int { registrations.filter { $0.status == .yes }.count }

    func startObserving(tournamentService: TournamentServicing) {
        observerTask?.cancel()
        observerTask = Task {
            let stream = tournamentService.observeRegistrations(for: session)
            for await regs in stream {
                guard !Task.isCancelled else { break }
                self.registrations = regs.sorted { $0.name < $1.name }
            }
        }
    }

    func setRSVP(_ status: RegistrationStatus, tournamentService: TournamentServicing) async {
        guard let user = currentUser else { return }
        do {
            try await tournamentService.setRegistrationStatus(status, userID: user.id, name: user.name, for: session)
        } catch {
            errorMessage = "Could not update RSVP."
        }
    }

    func checkIn(userID: String, name: String, tournamentService: TournamentServicing) async {
        do {
            session = try await tournamentService.checkInPlayer(userID: userID, name: name, in: session)
        } catch {
            errorMessage = "Could not check in player."
        }
    }

    /// Checked-in registrations converted to TournamentPlayer, ready to pre-populate the start sheet.
    var checkedInPlayers: [TournamentPlayer] {
        registrations
            .filter { $0.checkedInAt != nil }
            .map { TournamentPlayer(id: UUID().uuidString, name: $0.name, userID: $0.userID,
                                   played: 0, wins: 0, losses: 0, lastPlayedAt: 0, isActive: true) }
    }

    func startSession(courts: Int, players: [TournamentPlayer], tournamentService: TournamentServicing) async -> TournamentSession? {
        isLoading = true
        defer { isLoading = false }
        do {
            let active = try await tournamentService.startScheduledSession(session, courts: courts, players: players)
            session = active
            return active
        } catch {
            errorMessage = "Could not start session."
            return nil
        }
    }

    func cancel(tournamentService: TournamentServicing) async {
        do {
            session = try await tournamentService.cancelScheduledSession(session)
        } catch {
            errorMessage = "Could not cancel session."
        }
    }
}

// MARK: - View

struct ScheduledDayDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm: ScheduledDayViewModel
    var onSessionStarted: (TournamentSession) -> Void

    @State private var showCancelConfirm = false
    @State private var showStartSheet = false

    init(session: TournamentSession, currentUser: AppUser?, squadMemberIDs: [String], onSessionStarted: @escaping (TournamentSession) -> Void) {
        _vm = StateObject(wrappedValue: ScheduledDayViewModel(session: session, currentUser: currentUser, squadMemberIDs: squadMemberIDs))
        self.onSessionStarted = onSessionStarted
    }

    var body: some View {
        List {
            // MARK: Header info
            Section {
                if let start = vm.session.scheduledStart {
                    LabeledContent("Date", value: start.formatted(date: .complete, time: .omitted))
                    LabeledContent("Time", value: start.formatted(date: .omitted, time: .shortened))
                }
                LabeledContent("Courts", value: "\(vm.session.courts)")
                if let loc = vm.session.location {
                    LabeledContent("Location", value: loc)
                }
            }

            // MARK: RSVP (non-host squad members)
            if !vm.isHost && vm.session.status == .scheduled {
                Section("Your RSVP") {
                    HStack(spacing: 12) {
                        RSVPButton(label: "Going", systemImage: "checkmark.circle.fill", tint: .green,
                                   isSelected: vm.myRegistration?.status == .yes) {
                            Task { await vm.setRSVP(.yes, tournamentService: env.tournamentService) }
                        }
                        RSVPButton(label: "Maybe", systemImage: "questionmark.circle.fill", tint: .orange,
                                   isSelected: vm.myRegistration?.status == .maybe) {
                            Task { await vm.setRSVP(.maybe, tournamentService: env.tournamentService) }
                        }
                        RSVPButton(label: "Can't go", systemImage: "xmark.circle.fill", tint: .red,
                                   isSelected: vm.myRegistration?.status == .no) {
                            Task { await vm.setRSVP(.no, tournamentService: env.tournamentService) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: Registration list
            if !vm.registrations.isEmpty || vm.isHost {
                Section {
                    ForEach(vm.registrations) { reg in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reg.name).font(.body)
                                Text(reg.status.label)
                                    .font(.caption)
                                    .foregroundStyle(reg.status.color)
                            }
                            Spacer()
                            if vm.isHost && vm.session.status == .scheduled {
                                // Check-in toggle
                                Button {
                                    Task { await vm.checkIn(userID: reg.userID, name: reg.name, tournamentService: env.tournamentService) }
                                } label: {
                                    Image(systemName: reg.checkedInAt != nil ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(reg.checkedInAt != nil ? .orange : .secondary)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            } else if reg.checkedInAt != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Registered (\(vm.yesCount) going · \(vm.checkedInCount) checked in)")
                }
            }

            // MARK: Host actions
            if vm.isHost && vm.session.status == .scheduled {
                Section {
                    Button {
                        showStartSheet = true
                    } label: {
                        Label("Start Session", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.orange)
                    .disabled(vm.isLoading)

                    Text("\(vm.checkedInCount) checked in · tap Start to configure and launch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Cancel Game Day", role: .destructive) {
                        showCancelConfirm = true
                    }
                }
            }

            if vm.session.status == .cancelled {
                Section {
                    Label("This game day was cancelled.", systemImage: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }
            }
        }
        .navigationTitle(vm.session.title.isEmpty ? "Game Day" : vm.session.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { vm.startObserving(tournamentService: env.tournamentService) }
        .sheet(isPresented: $showStartSheet) {
            StartScheduledDaySheet(
                session: vm.session,
                initialPlayers: vm.checkedInPlayers,
                squadMemberIDs: vm.squadMemberIDs
            ) { courts, players in
                Task {
                    if let active = await vm.startSession(courts: courts, players: players,
                                                         tournamentService: env.tournamentService) {
                        onSessionStarted(active)
                    }
                }
            }
        }
        .confirmationDialog("Cancel this game day?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Cancel Game Day", role: .destructive) {
                Task { await vm.cancel(tournamentService: env.tournamentService) }
            }
        } message: {
            Text("All registered players will see it as cancelled.")
        }
    }
}

// MARK: - Supporting views

private struct RSVPButton: View {
    let label: String
    let systemImage: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? tint : .secondary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? tint : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? tint.opacity(0.12) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Start Scheduled Day Sheet

struct StartScheduledDaySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let session: TournamentSession
    let squadMemberIDs: [String]
    var onStarted: (Int, [TournamentPlayer]) -> Void

    @State private var courts: Int
    @State private var players: [TournamentPlayer]
    @State private var selectedIDs: Set<String>
    @State private var showPicker = false

    init(session: TournamentSession, initialPlayers: [TournamentPlayer],
         squadMemberIDs: [String], onStarted: @escaping (Int, [TournamentPlayer]) -> Void) {
        self.session = session
        self.squadMemberIDs = squadMemberIDs
        self.onStarted = onStarted
        _courts = State(initialValue: session.courts)
        _players = State(initialValue: initialPlayers)
        _selectedIDs = State(initialValue: Set(initialPlayers.map(\.id)))
    }

    private var selectedPlayers: [TournamentPlayer] {
        players.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Courts") {
                    Stepper("Courts: \(courts)", value: $courts, in: 1...4)
                }

                Section {
                    ForEach($players) { $player in
                        PlayerToggleRow(
                            player: $player,
                            isSelected: selectedIDs.contains(player.id),
                            onToggle: { on in
                                if on { selectedIDs.insert(player.id) }
                                else  { selectedIDs.remove(player.id) }
                            }
                        )
                    }
                    Button { showPicker = true } label: {
                        Label("Add More Players", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Today's Players (\(selectedPlayers.count))")
                } footer: {
                    if selectedPlayers.count < courts * 4 {
                        Text("Need at least \(courts * 4) players for \(courts) court(s).")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Start Session") {
                        onStarted(courts, selectedPlayers)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(selectedPlayers.isEmpty)
                }
            }
            .navigationTitle("Start Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                PlayerPickerSheet(squadMemberIDs: squadMemberIDs) { newPlayers in
                    let existingUserIDs = Set(players.compactMap(\.userID))
                    let existingNames   = Set(players.filter { $0.userID == nil }.map(\.name))
                    for p in newPlayers {
                        if let uid = p.userID {
                            if !existingUserIDs.contains(uid) {
                                players.append(p); selectedIDs.insert(p.id)
                            }
                        } else {
                            if !existingNames.contains(p.name) {
                                players.append(p); selectedIDs.insert(p.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension RegistrationStatus {
    var label: String {
        switch self {
        case .yes:   return "Going"
        case .maybe: return "Maybe"
        case .no:    return "Can't go"
        }
    }

    var color: Color {
        switch self {
        case .yes:   return .green
        case .maybe: return .orange
        case .no:    return .red
        }
    }
}
