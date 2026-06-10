import SwiftUI

// MARK: - FixedTeamSetupSheet

/// Shared sheet for building or editing fixed teams from a player roster.
/// Tap an unassigned player to slot them into the next empty spot (a new team is auto-created when needed).
/// Tap an assigned player to return them to the unassigned pool.
struct FixedTeamSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    let players: [GamePlayer]
    var initialTeams: [FixedTeam] = []
    var onSave: ([FixedTeam]) -> Void

    // draft state: list of [playerID] arrays (each up to 2)
    @State private var teams: [[String]] = []

    private var assignedIDs: Set<String> { Set(teams.flatMap { $0 }) }

    private var unassigned: [GamePlayer] {
        players.filter { !assignedIDs.contains($0.id) }
    }

    /// Valid once there's at least one complete pair. Players left in the unassigned
    /// pool are allowed — they simply sit out (not everyone in the game always plays).
    private var isValid: Bool {
        !teams.isEmpty && teams.allSatisfy { $0.count == 2 }
    }

    init(players: [GamePlayer],
         initialTeams: [FixedTeam] = [],
         onSave: @escaping ([FixedTeam]) -> Void) {
        self.players = players
        self.initialTeams = initialTeams
        self.onSave = onSave
        _teams = State(initialValue: initialTeams.map(\.playerIDs))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Teams section
                if !teams.isEmpty {
                    Section {
                        ForEach(teams.indices, id: \.self) { idx in
                            teamCard(index: idx)
                        }
                    } header: {
                        Text("Teams")
                    }
                }

                // MARK: Unassigned section
                if !unassigned.isEmpty {
                    Section {
                        ForEach(unassigned) { player in
                            Button {
                                assign(player)
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundStyle(.blue)
                                    Text(player.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("Tap to assign")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Unassigned (\(unassigned.count))")
                    } footer: {
                        Text("Players left here aren't on a team and will sit this one out.")
                    }
                }

                // MARK: Auto-assign
                Section {
                    Button {
                        autoAssign()
                    } label: {
                        Label("Auto-Assign Teams", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                    }
                }

                // MARK: Validation hint
                if !isValid && !teams.isEmpty {
                    Section {
                        Text(validationHint)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Set Up Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fixedTeams = buildFixedTeams()
                        dismiss()
                        onSave(fixedTeams)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Team card

    @ViewBuilder
    private func teamCard(index: Int) -> some View {
        let teamName = "Team \(index + 1)"
        let slots = teams[index]

        VStack(alignment: .leading, spacing: 6) {
            Text(teamName)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(0..<2) { slot in
                if slot < slots.count {
                    let playerID = slots[slot]
                    let name = players.first { $0.id == playerID }?.name ?? playerID
                    Button {
                        unassign(playerID: playerID, fromTeam: index)
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.green)
                            Text(name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.tertiary)
                        Text("Empty slot")
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func assign(_ player: GamePlayer) {
        // Find first team with an open slot
        if let idx = teams.firstIndex(where: { $0.count < 2 }) {
            teams[idx].append(player.id)
        } else {
            // All teams full — create a new one
            teams.append([player.id])
        }
    }

    private func unassign(playerID: String, fromTeam teamIndex: Int) {
        teams[teamIndex].removeAll { $0 == playerID }
        // Remove empty teams and renumber (renumbering is implicit from index)
        teams.removeAll { $0.isEmpty }
    }

    private func autoAssign() {
        let shuffled = players.shuffled()
        var result: [[String]] = []
        var idx = 0
        while idx + 1 < shuffled.count {
            result.append([shuffled[idx].id, shuffled[idx + 1].id])
            idx += 2
        }
        // If odd player out, leave them unassigned (they'll appear in the unassigned section)
        teams = result
    }

    private func buildFixedTeams() -> [FixedTeam] {
        teams.enumerated().map { idx, playerIDs in
            let existing = initialTeams.first { Set($0.playerIDs) == Set(playerIDs) }
            return FixedTeam(
                id: existing?.id ?? UUID().uuidString,
                name: "Team \(idx + 1)",
                playerIDs: playerIDs
            )
        }
    }

    // MARK: - Validation hint

    private var validationHint: String {
        let incompleteCount = teams.filter { $0.count < 2 }.count
        if incompleteCount > 0 {
            return "\(incompleteCount) team(s) still need a second player."
        }
        return ""
    }
}
