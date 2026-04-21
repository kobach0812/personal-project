import Combine
import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(notificationService: NotificationServicing) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            notifications = try await notificationService.fetchNotifications()
        } catch {
            errorMessage = "Could not load notifications."
        }
    }
}
