import Foundation

struct AppUser: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var avatarURL: URL?
    /// The squad currently driving Feed / Camera / Game / widget.
    var activeSquadID: String?
    let createdAt: Date
    var updatedAt: Date
}
