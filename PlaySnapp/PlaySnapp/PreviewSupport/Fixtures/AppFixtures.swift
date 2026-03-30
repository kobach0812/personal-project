import Foundation

enum AppFixtures {
    nonisolated static let sampleUser = AppUser(
        id: "user-1",
        name: "Alex Carter",
        primarySport: .football,
        avatarURL: nil,
        squadID: "squad-1",
        createdAt: .now,
        updatedAt: .now
    )

    nonisolated static let sampleSquad = Squad(
        id: "squad-1",
        name: "Tuesday Five-a-Side",
        sport: .football,
        memberIDs: ["user-1", "user-2", "user-3"],
        inviteCode: "PLAY5",
        createdAt: .now
    )

    nonisolated static let samplePlays: [Play] = [
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

    nonisolated static let sampleNotifications: [AppNotification] = [
        AppNotification(
            id: "notification-1",
            type: .newPlay,
            title: "New squad play",
            message: "Maya just shared a new moment.",
            createdAt: .now.addingTimeInterval(-300),
            playID: "play-1",
            readAt: nil
        ),
        AppNotification(
            id: "notification-2",
            type: .reaction,
            title: "Reaction received",
            message: "Jordan reacted to your last post.",
            createdAt: .now.addingTimeInterval(-1800),
            playID: "play-2",
            readAt: .now.addingTimeInterval(-1200)
        )
    ]
}
