import Foundation

protocol PlayServicing {
    func fetchFeed() async throws -> [Play]
    func toggleReaction(for playID: String, emoji: String) async throws -> [Play]
}

actor StubPlayService: PlayServicing {
    private var plays = Play.samples

    func fetchFeed() async throws -> [Play] {
        plays.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func toggleReaction(for playID: String, emoji: String) async throws -> [Play] {
        guard let index = plays.firstIndex(where: { $0.id == playID }) else {
            return plays
        }

        var updated = plays[index]
        let currentlySelected = updated.currentUserReaction == emoji
        let existingCount = updated.reactionSummary[emoji, default: 0]

        if currentlySelected {
            updated.currentUserReaction = nil
            updated.reactionSummary[emoji] = max(existingCount - 1, 0)
            if updated.reactionSummary[emoji] == 0 {
                updated.reactionSummary[emoji] = nil
            }
        } else {
            if let priorEmoji = updated.currentUserReaction {
                let priorCount = updated.reactionSummary[priorEmoji, default: 0]
                updated.reactionSummary[priorEmoji] = max(priorCount - 1, 0)
                if updated.reactionSummary[priorEmoji] == 0 {
                    updated.reactionSummary[priorEmoji] = nil
                }
            }

            updated.currentUserReaction = emoji
            updated.reactionSummary[emoji] = existingCount + 1
        }

        plays[index] = updated
        return plays.sorted(by: { $0.createdAt > $1.createdAt })
    }
}
