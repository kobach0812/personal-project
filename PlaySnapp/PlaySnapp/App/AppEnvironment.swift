import Combine
import Foundation

enum AppDataSource {
    case development
    case firebasePrepared
}

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
}

extension AppEnvironment {
    static func bootstrap(dataSource: AppDataSource = .development) -> AppEnvironment {
        FirebaseConfiguration.configure()

        switch dataSource {
        case .development:
            return makeDevelopmentEnvironment()
        case .firebasePrepared:
            return makeFirebasePreparedEnvironment()
        }
    }

    private static func makeDevelopmentEnvironment() -> AppEnvironment {
        AppEnvironment(
            authService: StubAuthService(),
            squadService: StubSquadService(),
            playService: StubPlayService(),
            storageService: StubStorageService(),
            notificationService: StubNotificationService(),
            widgetSyncService: LocalWidgetSyncService()
        )
    }

    private static func makeFirebasePreparedEnvironment() -> AppEnvironment {
        AppEnvironment(
            authService: FirebaseAuthService(),
            squadService: StubSquadService(),
            playService: StubPlayService(),
            storageService: FirebaseStorageService(),
            notificationService: StubNotificationService(),
            widgetSyncService: LocalWidgetSyncService()
        )
    }
}
