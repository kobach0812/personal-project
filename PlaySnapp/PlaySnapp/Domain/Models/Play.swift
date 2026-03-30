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
    var thumbnailURL: URL?
    var caption: String?
    var durationSeconds: Int?
    var reactionSummary: [String: Int]
    var currentUserReaction: String?
    let createdAt: Date
}
