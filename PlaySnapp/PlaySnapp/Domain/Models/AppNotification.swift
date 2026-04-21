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
    /// User ID of whoever triggered this notification (poster or reactor).
    var actorID: String?
    /// User ID of the intended recipient. Used by Cloud Functions for fan-out.
    var recipientID: String?
    /// Squad context. Used for deep-link routing to the correct feed.
    var squadID: String?
    var createdAt: Date
    var playID: String?
    var readAt: Date?
}
