import SwiftUI

// MARK: - BracketListView

struct BracketListView: View {
    @EnvironmentObject private var env: AppEnvironment

    let tournament: Tournament
    let currentUser: AppUser?

    @State private var brackets: [BracketTournament] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreate = false
    @State private var navigateTo: BracketTournament?

    private var isOrganizer: Bool {
        tournament.createdBy == (currentUser?.id ?? "")
    }

    var body: some View {
        content
            .toolbar {
                if isOrganizer {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showCreate = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateBracketSheet(tournament: tournament,
                                   createdBy: currentUser?.id ?? "") { newBracket in
                    brackets.insert(newBracket, at: 0)
                }
            }
            .navigationDestination(item: $navigateTo) { bracket in
                BracketDetailView(bracket: bracket, currentUser: currentUser)
            }
            .task { await load() }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if brackets.isEmpty {
            ContentUnavailableView(
                "No bracket tournaments yet",
                systemImage: "trophy",
                description: Text(isOrganizer
                    ? "Tap + to create one."
                    : "The organizer hasn't created any bracket tournaments.")
            )
        } else {
            List {
                ForEach(brackets) { bracket in
                    Button { navigateTo = bracket } label: {
                        BracketRow(bracket: bracket)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            brackets = try await env.bracketTournamentService.fetchBrackets(
                in: tournament.id,
                squadID: tournament.squadID
            )
        } catch {
            errorMessage = "Could not load bracket tournaments."
        }
    }
}

