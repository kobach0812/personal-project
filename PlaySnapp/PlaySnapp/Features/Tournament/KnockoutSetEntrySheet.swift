import SwiftUI

/// Organizer-only sheet for entering a single set of a best-of-N knockout match.
/// One set is appended per save; the organizer reopens the card to enter the next set
/// until a team reaches the win threshold. Draws are not allowed within a set.
struct KnockoutSetEntrySheet: View {
    let teamAName: String
    let teamBName: String
    /// Sets already recorded, so the sheet can show the running tally and next set number.
    let existingSets: [SetScore]
    let setsToWin: Int
    let onSave: (SetScore) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scoreAText: String = ""
    @State private var scoreBText: String = ""
    @State private var validationError: String?

    private var setsWonA: Int { existingSets.filter { $0.teamAScore > $0.teamBScore }.count }
    private var setsWonB: Int { existingSets.filter { $0.teamBScore > $0.teamAScore }.count }
    private var nextSetNumber: Int { existingSets.count + 1 }

    private var parsedScores: (Int, Int)? {
        guard let a = Int(scoreAText.trimmingCharacters(in: .whitespaces)),
              let b = Int(scoreBText.trimmingCharacters(in: .whitespaces))
        else { return nil }
        return (a, b)
    }

    private var canSave: Bool {
        guard let (a, b) = parsedScores else { return false }
        return a >= 0 && b >= 0 && a != b
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(teamAName)
                        Spacer()
                        Text("\(setsWonA)").foregroundStyle(.secondary).monospacedDigit()
                        Text("–").foregroundStyle(.secondary)
                        Text("\(setsWonB)").foregroundStyle(.secondary).monospacedDigit()
                        Text(teamBName)
                    }
                } header: {
                    Text("Sets won — first to \(setsToWin)")
                }

                Section {
                    scoreField(team: teamAName, text: $scoreAText)
                    scoreField(team: teamBName, text: $scoreBText)
                } header: {
                    Text("Set \(nextSetNumber)")
                } footer: {
                    if let validationError {
                        Text(validationError).foregroundStyle(ThemeColor.loss)
                    } else {
                        Text("Enter this set's score. A draw is not allowed.")
                    }
                }
            }
            .navigationTitle("Enter Set")
            .navigationBarTitleDisplayMode(.inline)
            .tint(ThemeColor.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func scoreField(team: String, text: Binding<String>) -> some View {
        HStack {
            Text(team)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func save() {
        guard let (a, b) = parsedScores else {
            validationError = "Enter a number for both teams."
            return
        }
        guard a >= 0, b >= 0 else {
            validationError = "Scores cannot be negative."
            return
        }
        guard a != b else {
            validationError = "Draws are not allowed — one team must win the set."
            return
        }
        onSave(SetScore(teamAScore: a, teamBScore: b))
        dismiss()
    }
}
