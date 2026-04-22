import Combine
import Foundation

enum AppDataSource {
    case development
    case firebasePrepared
}

@MainActor
final class AppEnvironment: ObservableObject {
    let authService: AuthServicing
    let onboardingProgressService: OnboardingProgressServicing
    let userProfileService: UserProfileServicing
    let squadService: SquadServicing
    let playService: PlayServicing
    let storageService: StorageServicing
    let notificationService: NotificationServicing
    let widgetSyncService: WidgetSyncServicing
    let tournamentService: TournamentServicing

    init(
        authService: AuthServicing,
        onboardingProgressService: OnboardingProgressServicing,
        userProfileService: UserProfileServicing,
        squadService: SquadServicing,
        playService: PlayServicing,
        storageService: StorageServicing,
        notificationService: NotificationServicing,
        widgetSyncService: WidgetSyncServicing,
        tournamentService: TournamentServicing
    ) {
        self.authService = authService
        self.onboardingProgressService = onboardingProgressService
        self.userProfileService = userProfileService
        self.squadService = squadService
        self.playService = playService
        self.storageService = storageService
        self.notificationService = notificationService
        self.widgetSyncService = widgetSyncService
        self.tournamentService = tournamentService
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
        let sessionStore = StubSessionStore()

        return AppEnvironment(
            authService: StubAuthService(sessionStore: sessionStore),
            onboardingProgressService: StubOnboardingProgressService(sessionStore: sessionStore),
            userProfileService: StubUserProfileService(sessionStore: sessionStore),
            squadService: StubSquadService(sessionStore: sessionStore),
            playService: StubPlayService(),
            storageService: StubStorageService(),
            notificationService: StubNotificationService(),
            widgetSyncService: LocalWidgetSyncService(),
            tournamentService: StubTournamentService()
        )
    }

    private static func makeFirebasePreparedEnvironment() -> AppEnvironment {
        let authGateway = FirebaseAuthGateway()
        let sessionStore = FirebaseSessionDocumentStore()

        return AppEnvironment(
            authService: FirebaseAuthService(
                authGateway: authGateway,
                sessionStore: sessionStore
            ),
            onboardingProgressService: FirebaseOnboardingProgressService(
                authGateway: authGateway,
                sessionStore: sessionStore
            ),
            userProfileService: FirebaseUserProfileService(
                authGateway: authGateway,
                sessionStore: sessionStore
            ),
            squadService: FirebaseSquadService(authGateway: authGateway),
            playService: FirebasePlayService(authGateway: authGateway),
            storageService: FirebaseStorageService(),
            notificationService: StubNotificationService(),
            widgetSyncService: LocalWidgetSyncService(),
            tournamentService: FirebaseTournamentService()
        )
    }
}
