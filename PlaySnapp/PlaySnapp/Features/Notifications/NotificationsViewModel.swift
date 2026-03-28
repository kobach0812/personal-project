import Combine
import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []

    func load(notificationService: NotificationServicing) async {
        guard notifications.isEmpty else {
            return
        }

        notifications = (try? await notificationService.fetchNotifications()) ?? []
    }
}
