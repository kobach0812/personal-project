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
