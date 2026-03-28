import Combine
import Foundation

enum AppPhase: Equatable {
    case loading
    case auth
    case profileSetup
    case squadSetup
    case widgetIntro
    case main
}

enum MainTab: Hashable {
    case camera
    case feed
    case notifications
    case profile
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var phase: AppPhase = .loading
    @Published var selectedTab: MainTab = .camera

    func bootstrap(using authService: AuthServicing) async {
        phase = .loading

        do {
            let session = try await authService.restoreSession()
            phase = destination(for: session)
        } catch {
            phase = .auth
        }
    }

    func handleSessionUpdate(_ session: AppSession?) {
        phase = destination(for: session)
    }

    func openMain(tab: MainTab = .camera) {
        selectedTab = tab
        phase = .main
    }

    private func destination(for session: AppSession?) -> AppPhase {
        guard let session else {
            return .auth
        }

        if !session.hasCompletedProfile {
            return .profileSetup
        }

        if !session.hasJoinedSquad {
            return .squadSetup
        }

        if !session.hasSeenWidgetIntro {
            return .widgetIntro
        }

        return .main
    }
}
