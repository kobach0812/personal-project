import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let authService: AuthServicing
    let squadService: SquadServicing
    let playService: PlayServicing
    let storageService: StorageServicing
    let notificationService: NotificationServicing
    let widgetSyncService: WidgetSyncServicing

    init(
        authService: AuthServicing,
        squadService: SquadServicing,
        playService: PlayServicing,
        storageService: StorageServicing,
        notificationService: NotificationServicing,
        widgetSyncService: WidgetSyncServicing
    ) {
        self.authService = authService
        self.squadService = squadService
        self.playService = playService
        self.storageService = storageService
        self.notificationService = notificationService
        self.widgetSyncService = widgetSyncService
    }

    static func bootstrap() -> AppEnvironment {
        let authService = StubAuthService()
        let squadService = StubSquadService()
        let playService = StubPlayService()
        let storageService = StubStorageService()
        let notificationService = StubNotificationService()
        let widgetSyncService = StubWidgetSyncService()

        return AppEnvironment(
            authService: authService,
            squadService: squadService,
            playService: playService,
            storageService: storageService,
            notificationService: notificationService,
            widgetSyncService: widgetSyncService
        )
    }
}
