import Foundation

struct PlayReaction: Codable, Equatable, Sendable {
    let userID: String
    var emoji: String
    let createdAt: Date
}
