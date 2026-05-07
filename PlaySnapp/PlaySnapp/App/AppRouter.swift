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
    case game
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var phase: AppPhase = .loading
    @Published var selectedTab: MainTab = .camera
    @Published var pendingInviteCode: String?
    @Published var pendingAddUserID: String?

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

    func handleInviteURL(_ url: URL) {
        guard url.scheme == "playsnapp",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }

        switch url.host {
        case "join":
            guard let rawCode = components.queryItems?.first(where: { $0.name == "code" })?.value,
                  !rawCode.isEmpty
            else { return }
            pendingInviteCode = rawCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if phase == .main { selectedTab = .profile }

        case "add":
            guard let userID = components.queryItems?.first(where: { $0.name == "userID" })?.value,
                  !userID.isEmpty
            else { return }
            pendingAddUserID = userID
            if phase == .main { selectedTab = .profile }

        default:
            break
        }
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
