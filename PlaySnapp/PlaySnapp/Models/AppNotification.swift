import Foundation

enum AppNotificationType: String, Codable, Sendable {
    case newPlay
    case reaction
}

struct AppNotification: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var type: AppNotificationType
    var title: String
    var message: String
    var createdAt: Date
    var playID: String?
    var readAt: Date?
}

extension AppNotification {
    nonisolated static let samples: [AppNotification] = [
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
