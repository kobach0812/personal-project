import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = FeedViewModel()
    @State private var navigateToScheduledSession: TournamentSession?

    private var isToday: Bool {
        guard let start = viewModel.nextScheduledSession?.scheduledStart else { return false }
        return Calendar.current.isDateInToday(start)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.plays.isEmpty {
                    ProgressView("Loading squad feed...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.plays.isEmpty {
                    ContentUnavailableView(
                        "Could not load feed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.plays.isEmpty {
                    VStack {
                        if isToday, let session = viewModel.nextScheduledSession {
                            ScheduledDayBanner(session: session) {
                                navigateToScheduledSession = session
                            }
                        }
                        ContentUnavailableView(
                            "No plays yet",
                            systemImage: "sportscourt",
                            description: Text("The first post from your squad will appear here.")
                        )
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if isToday, let session = viewModel.nextScheduledSession {
                                ScheduledDayBanner(session: session) {
                                    navigateToScheduledSession = session
                                }
                            }
                            ForEach(viewModel.plays) { play in
                                NavigationLink {
                                    PlayDetailView(play: play)
                                } label: {
                                    PlayCardView(play: play) { emoji in
                                        Task {
                                            await viewModel.toggleReaction(
                                                emoji,
                                                for: play.id,
                                                playService: environment.playService
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        await viewModel.load(playService: environment.playService)
                    }
                }
            }
            .navigationTitle("Squad feed")
            .onAppear {
                Task {
                    await viewModel.load(playService: environment.playService)
                    if let squadID = try? await environment.squadService.fetchCurrentSquad()?.id {
                        await viewModel.loadNextScheduledSession(
                            squadID: squadID,
                            tournamentService: environment.tournamentService
                        )
                    }
                }
            }
            .navigationDestination(item: $navigateToScheduledSession) { session in
                ScheduledDayDetailView(
                    session: session,
                    currentUser: nil,
                    squadMemberIDs: []
                ) { _ in
                    navigateToScheduledSession = nil
                }
            }
        }
    }
}
