import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var plays: [Play] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(playService: PlayServicing) async {
        isLoading = true
        errorMessage = nil

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
            let updatedPlay = try await playService.toggleReaction(for: playID, emoji: emoji)
            if let index = plays.firstIndex(where: { $0.id == updatedPlay.id }) {
                plays[index] = updatedPlay
            }
        } catch {
            errorMessage = "Reaction failed."
        }
    }
}
