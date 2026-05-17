import SwiftUI

// MARK: - CreateBracketSheet

/// Host flow for creating a new bracket inside a parent Tournament.
/// Steps in one screen: title → set up teams (reuses FixedTeamSetupSheet) →
/// pick group count → assign each team to a group → Create.
struct CreateBracketSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let tournament: Tournament
    let createdBy: String
    var onCreated: (BracketTournament) -> Void

    @State private var title: String = ""
    @State private var teams: [FixedTeam] = []
    @State private var groupCount: Int = 1
    /// Mapping team.id → group index (0-based)
    @State private var teamGroupAssignment: [String: Int] = [:]
    @State private var showTeamSetup = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var groupNames: [String] {
        (0..<groupCount).map { String(UnicodeScalar(65 + $0)!) } // A, B, C, D
    }

    /// Each group needs ≥ 2 teams. With 1 group: ≥ 2 teams total.
    private var validation: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter a name." }
        if teams.count < 2 { return "Set up at least two teams." }
        if groupCount > 1 {
            for idx in 0..<groupCount {
                let count = teams.filter { (teamGroupAssignment[$0.id] ?? 0) == idx }.count
                if count < 2 { return "Group \(groupNames[idx]) needs at least 2 teams." }
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Tuesday Doubles Bracket", text: $title)
                }

                Section {
                    if teams.isEmpty {
                        Button {
                            showTeamSetup = true
                        } label: {
                            Label("Set Up Teams", systemImage: "person.2.badge.plus")
                        }
                    } else {
                        ForEach(teams) { team in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name).font(.body)
                                    Text(playerNames(for: team))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if groupCount > 1 {
                                    Picker("Group", selection: Binding(
                                        get: { teamGroupAssignment[team.id] ?? 0 },
                                        set: { teamGroupAssignment[team.id] = $0 }
                                    )) {
                                        ForEach(0..<groupCount, id: \.self) { idx in
                                            Text(groupNames[idx]).tag(idx)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                }
                            }
                        }
                        Button {
                            showTeamSetup = true
                        } label: {
                            Label("Edit Teams", systemImage: "pencil")
                        }
                    }
                } header: {
                    Text("Teams (\(teams.count))")
                }

                if teams.count >= 2 {
                    Section("Groups") {
                        Stepper("Number of groups: \(groupCount)", value: $groupCount, in: 1...4)
                        if groupCount > 1 {
                            Text("Assign each team above to a group.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let hint = validation {
                    Section {
                        Text(hint).font(.footnote).foregroundStyle(.orange)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Create Bracket") {
                        Task { await create() }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(validation != nil || isCreating)
                }
            }
            .disabled(isCreating)
            .navigationTitle("New Bracket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showTeamSetup) {
                FixedTeamSetupSheet(
                    players: tournament.players,
                    initialTeams: teams
                ) { newTeams in
                    teams = newTeams
                    // Preserve previous assignments; default new teams to group 0
                    var updated: [String: Int] = [:]
                    for t in newTeams {
                        updated[t.id] = teamGroupAssignment[t.id] ?? 0
                    }
                    teamGroupAssignment = updated
                }
            }
        }
    }

    // MARK: - Actions

    private func playerNames(for team: FixedTeam) -> String {
        team.playerIDs
            .compactMap { id in tournament.players.first { $0.id == id }?.name }
            .joined(separator: " & ")
    }

    private func buildGroups() -> [BracketGroup] {
        (0..<groupCount).map { idx in
            let memberTeams: [FixedTeam] = groupCount == 1
                ? teams
                : teams.filter { (teamGroupAssignment[$0.id] ?? 0) == idx }
            return BracketGroup(
                id: UUID().uuidString,
                name: groupNames[idx],
                teams: memberTeams,
                matches: [],
                advanceCount: nil
            )
        }
    }

    private func create() async {
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            let bracket = try await env.bracketTournamentService.createBracket(
                in: tournament.id,
                squadID: tournament.squadID,
                createdBy: createdBy,
                title: title.trimmingCharacters(in: .whitespaces),
                groups: buildGroups()
            )
            dismiss()
            onCreated(bracket)
        } catch {
            errorMessage = "Could not create bracket."
        }
    }
}
