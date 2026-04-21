import Foundation

enum MediaType: String, Codable, Sendable {
    case photo
    case video
}

struct Play: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let squadID: String
    let senderID: String
    var senderName: String
    var mediaType: MediaType
    var mediaURL: URL
    /// Firebase Storage path. Required for server-side cleanup and future migrations.
    /// Nil only in stub/preview contexts where no real upload has occurred.
    var storagePath: String?
    var thumbnailURL: URL?
    var caption: String?
    var durationSeconds: Int?
    var reactionSummary: [String: Int]
    var currentUserReaction: String?
    let createdAt: Date
}
