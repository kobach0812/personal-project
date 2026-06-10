import Combine
import SwiftUI

// MARK: - ViewModel

@MainActor
final class ScheduledDayViewModel: ObservableObject {
    @Published var session: GameSession
    @Published var registrations: [Registration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var observerTask: Task<Void, Never>?
    let currentUser: AppUser?
    let squadMemberIDs: [String]

    init(session: GameSession, currentUser: AppUser?, squadMemberIDs: [String]) {
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

    func startObserving(gameService: GameServicing) {
        observerTask?.cancel()
        observerTask = Task {
            let stream = gameService.observeRegistrations(for: session)
            for await regs in stream {
                guard !Task.isCancelled else { break }
                self.registrations = regs.sorted { $0.name < $1.name }
            }
        }
    }

    func setRSVP(_ status: RegistrationStatus, gameService: GameServicing) async {
        guard let user = currentUser else { return }
        do {
            try await gameService.setRegistrationStatus(status, userID: user.id, name: user.name, for: session)
        } catch {
            errorMessage = "Could not update RSVP."
        }
    }

    func checkIn(userID: String, name: String, gameService: GameServicing) async {
        do {
            session = try await gameService.checkInPlayer(userID: userID, name: name, in: session)
        } catch {
            errorMessage = "Could not check in player."
        }
    }

    /// Checked-in registrations converted to GamePlayer, ready to pre-populate the start sheet.
    var checkedInPlayers: [GamePlayer] {
        registrations
            .filter { $0.checkedInAt != nil }
            .map { GamePlayer(id: UUID().uuidString, name: $0.name, userID: $0.userID,
                                   played: 0, wins: 0, losses: 0, lastPlayedAt: 0, isActive: true) }
    }

    func startSession(courts: Int, players: [GamePlayer], gameService: GameServicing) async -> GameSession? {
        isLoading = true
        defer { isLoading = false }
        do {
            let active = try await gameService.startScheduledSession(session, courts: courts, players: players)
            session = active
            return active
        } catch {
            errorMessage = "Could not start session."
            return nil
        }
    }

    func cancel(gameService: GameServicing) async {
        do {
            session = try await gameService.cancelScheduledSession(session)
        } catch {
            errorMessage = "Could not cancel session."
        }
    }
}

// MARK: - View

struct ScheduledDayDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm: ScheduledDayViewModel
    var onSessionStarted: (GameSession) -> Void

    @State private var showCancelConfirm = false
    @State private var showStartSheet = false

    init(session: GameSession, currentUser: AppUser?, squadMemberIDs: [String], onSessionStarted: @escaping (GameSession) -> Void) {
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
                            Task { await vm.setRSVP(.yes, gameService: env.gameService) }
                        }
                        RSVPButton(label: "Maybe", systemImage: "questionmark.circle.fill", tint: .orange,
                                   isSelected: vm.myRegistration?.status == .maybe) {
                            Task { await vm.setRSVP(.maybe, gameService: env.gameService) }
                        }
                        RSVPButton(label: "Can't go", systemImage: "xmark.circle.fill", tint: .red,
                                   isSelected: vm.myRegistration?.status == .no) {
                            Task { await vm.setRSVP(.no, gameService: env.gameService) }
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
                                    Task { await vm.checkIn(userID: reg.userID, name: reg.name, gameService: env.gameService) }
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
        .task { vm.startObserving(gameService: env.gameService) }
        .sheet(isPresented: $showStartSheet) {
            StartScheduledDaySheet(
                session: vm.session,
                initialPlayers: vm.checkedInPlayers,
                squadMemberIDs: vm.squadMemberIDs
            ) { courts, players in
                Task {
                    if let active = await vm.startSession(courts: courts, players: players,
                                                         gameService: env.gameService) {
                        onSessionStarted(active)
                    }
                }
            }
        }
        .confirmationDialog("Cancel this game day?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Cancel Game Day", role: .destructive) {
                Task { await vm.cancel(gameService: env.gameService) }
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

    let session: GameSession
    let squadMemberIDs: [String]
    var onStarted: (Int, [GamePlayer]) -> Void

    @State private var courts: Int
    @State private var players: [GamePlayer]
    @State private var selectedIDs: Set<String>

    init(session: GameSession, initialPlayers: [GamePlayer],
         squadMemberIDs: [String], onStarted: @escaping (Int, [GamePlayer]) -> Void) {
        self.session = session
        self.squadMemberIDs = squadMemberIDs
        self.onStarted = onStarted
        _courts = State(initialValue: session.courts)
        _players = State(initialValue: initialPlayers)
        _selectedIDs = State(initialValue: Set(initialPlayers.map(\.id)))
    }

    private var selectedPlayers: [GamePlayer] {
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
