import Foundation

actor StubNotificationService: NotificationServicing {
    func fetchNotifications() async throws -> [AppNotification] {
        AppFixtures.sampleNotifications.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func registerCurrentDevice() async throws {
        // Placeholder until APNs/FCM are wired in.
    }
}
