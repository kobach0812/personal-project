import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = FeedViewModel()

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
                    ContentUnavailableView(
                        "No plays yet",
                        systemImage: "sportscourt",
                        description: Text("The first post from your squad will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
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
            .task {
                await viewModel.load(playService: environment.playService)
            }
        }
    }
}
