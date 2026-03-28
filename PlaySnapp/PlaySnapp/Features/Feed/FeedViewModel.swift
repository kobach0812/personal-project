import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var plays: [Play] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(playService: PlayServicing) async {
        guard plays.isEmpty else {
            return
        }

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            plays = try await playService.fetchFeed()
        } catch {
            errorMessage = "Could not load the feed."
        }
    }

    func toggleReaction(
        _ emoji: String,
        for playID: String,
        playService: PlayServicing
    ) async {
        do {
            plays = try await playService.toggleReaction(for: playID, emoji: emoji)
        } catch {
            errorMessage = "Reaction failed."
        }
    }
}
