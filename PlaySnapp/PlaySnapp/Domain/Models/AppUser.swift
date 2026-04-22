import Foundation

struct AppUser: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var avatarURL: URL?
    var squadID: String?
    let createdAt: Date
    var updatedAt: Date
}
