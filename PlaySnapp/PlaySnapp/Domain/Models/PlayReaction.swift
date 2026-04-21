import Foundation

struct PlayReaction: Codable, Equatable, Sendable {
    let userID: String
    var emoji: String
    let createdAt: Date
}

extension PlayReaction {
    /// The fixed set of emojis a user can react with. Add new entries here to extend reactions app-wide.
    static let availableEmojis: [String] = ["🔥", "💪", "👏"]
}
