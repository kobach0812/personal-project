import SwiftUI

/// Organizer-only sheet for entering a single-set group match score.
/// Rules: both scores required, non-negative, and must not be equal (no draws).
struct GroupScoreEntrySheet: View {
    let teamAName: String
    let teamBName: String
    let onSave: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scoreAText: String = ""
    @State private var scoreBText: String = ""
    @State private var validationError: String?

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
                        TextField("0", text: $scoreAText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text(teamBName)
                        Spacer()
                        TextField("0", text: $scoreBText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Score")
                } footer: {
                    if let validationError {
                        Text(validationError).foregroundStyle(.red)
                    } else {
                        Text("Scores must be non-negative and a draw is not allowed.")
                    }
                }
            }
            .navigationTitle("Enter Score")
            .navigationBarTitleDisplayMode(.inline)
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
            validationError = "Draws are not allowed — one team must win."
            return
        }
        onSave(a, b)
        dismiss()
    }
}
