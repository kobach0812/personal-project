import Foundation

protocol NotificationServicing {
    func fetchNotifications() async throws -> [AppNotification]
    func registerCurrentDevice() async throws
}
