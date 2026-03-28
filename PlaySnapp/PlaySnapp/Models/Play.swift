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

extension Play {
    nonisolated static let samples: [Play] = [
        Play(
            id: "play-1",
            squadID: "squad-1",
            senderID: "user-2",
            senderName: "Maya",
            mediaType: .photo,
            mediaURL: URL(string: "https://example.com/plays/1.jpg")!,
            thumbnailURL: nil,
            caption: "Top bins before work.",
            durationSeconds: nil,
            reactionSummary: ["🔥": 2, "👏": 1],
            currentUserReaction: nil,
            createdAt: .now.addingTimeInterval(-900)
        ),
        Play(
            id: "play-2",
            squadID: "squad-1",
            senderID: "user-3",
            senderName: "Jordan",
            mediaType: .video,
            mediaURL: URL(string: "https://example.com/plays/2.mov")!,
            thumbnailURL: URL(string: "https://example.com/plays/2.jpg")!,
            caption: "Quick finishing drill.",
            durationSeconds: 14,
            reactionSummary: ["💪": 3],
            currentUserReaction: "💪",
            createdAt: .now.addingTimeInterval(-3600)
        )
    ]
}
