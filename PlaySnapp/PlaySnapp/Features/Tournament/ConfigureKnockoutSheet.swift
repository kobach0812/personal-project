import SwiftUI

/// Organizer-only sheet to configure the knockout phase once the group stage is complete.
/// Picks how many teams advance from each group (top N by standings) and the best-of-N
/// set count for knockout matches. The advancing total must land in `validAdvancingRange`
/// — the same 2…8 window the engine's `startingRound` supports.
struct ConfigureKnockoutSheet: View {
    let groups: [BracketGroup]
    let onGenerate: ([String: Int], Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var advanceCounts: [String: Int]
    @State private var bestOf: Int

    private static let bestOfOptions = [1, 3, 5]
    private static let validAdvancingRange = 2...8

    init(groups: [BracketGroup], onGenerate: @escaping ([String: Int], Int) -> Void) {
        self.groups = groups
        self.onGenerate = onGenerate
        // Default: top 2 per group (or the whole group if it has fewer than 2 teams).
        let defaults = Dictionary(uniqueKeysWithValues: groups.map { group in
            (group.id, min(2, max(1, group.teams.count)))
        })
        _advanceCounts = State(initialValue: defaults)
        _bestOf = State(initialValue: 3)
    }

    private var totalAdvancing: Int {
        groups.reduce(0) { $0 + (advanceCounts[$1.id] ?? 0) }
    }

    private var canGenerate: Bool {
        Self.validAdvancingRange.contains(totalAdvancing)
    }

    var body: some View {
        NavigationStack {
            Form {
                advanceSection
                bestOfSection
            }
            .navigationTitle("Configure Knockout")
            .navigationBarTitleDisplayMode(.inline)
            .tint(ThemeColor.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        onGenerate(advanceCounts, bestOf)
                        dismiss()
                    }
                    .disabled(!canGenerate)
                }
            }
        }
    }

    @ViewBuilder
    private var advanceSection: some View {
        Section {
            ForEach(groups) { group in
                Stepper(value: binding(for: group), in: 1...max(1, group.teams.count)) {
                    HStack {
                        Text("Group \(group.name)")
                        Spacer()
                        Text("Top \(advanceCounts[group.id] ?? 0)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        } header: {
            Text("Teams advancing per group")
        } footer: {
            HStack(spacing: 6) {
                Image(systemName: canGenerate ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(canGenerate ? ThemeColor.accent : ThemeColor.loss)
                Text("Total advancing: \(totalAdvancing)")
                    .foregroundStyle(canGenerate ? ThemeColor.textSecondary : ThemeColor.loss)
                if !canGenerate {
                    Text("— must be 2–8")
                        .foregroundStyle(ThemeColor.loss)
                }
            }
        }
    }

    @ViewBuilder
    private var bestOfSection: some View {
        Section {
            Picker("Best of", selection: $bestOf) {
                ForEach(Self.bestOfOptions, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Sets per knockout match")
        } footer: {
            Text("First to \((bestOf + 1) / 2) set\((bestOf + 1) / 2 == 1 ? "" : "s") wins each match.")
        }
    }

    private func binding(for group: BracketGroup) -> Binding<Int> {
        Binding(
            get: { advanceCounts[group.id] ?? 0 },
            set: { advanceCounts[group.id] = $0 }
        )
    }
}
