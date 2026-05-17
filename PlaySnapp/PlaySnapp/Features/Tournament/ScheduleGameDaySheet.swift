import SwiftUI

struct ScheduleGameDaySheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let tournament: Tournament
    var onScheduled: (TournamentSession) -> Void

    @State private var title = ""
    @State private var scheduledStart = Date.now.nextEveningRounded()
    @State private var courts = 1
    @State private var location = ""
    @State private var isScheduling = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Tuesday Night Badminton", text: $title)
                }

                Section("Date & Time") {
                    DatePicker("Starts", selection: $scheduledStart, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Courts") {
                    Stepper("Courts: \(courts)", value: $courts, in: 1...4)
                }

                Section("Location (optional)") {
                    TextField("e.g. Court 3, Eastern Park", text: $location)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section {
                    Button("Schedule") { Task { await schedule() } }
                        .frame(maxWidth: .infinity)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isScheduling)
                }
            }
            .disabled(isScheduling)
            .navigationTitle("Schedule Game Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func schedule() async {
        isScheduling = true
        errorMessage = nil
        defer { isScheduling = false }
        do {
            let session = try await env.tournamentService.scheduleSession(
                for: tournament,
                title: title.trimmingCharacters(in: .whitespaces),
                scheduledStart: scheduledStart,
                courts: courts,
                location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces)
            )
            dismiss()
            onScheduled(session)
        } catch {
            errorMessage = "Could not schedule game day."
        }
    }
}

private extension Date {
    /// Returns tomorrow at 8pm, rounded to the nearest 30 min.
    func nextEveningRounded() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: self)
        comps.day = (comps.day ?? 0) + 1
        comps.hour = 20
        comps.minute = 0
        comps.second = 0
        return Calendar.current.date(from: comps) ?? self
    }
}
