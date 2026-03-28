import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user = AppUser.sample
    @Published var squad: Squad?

    func load(squadService: SquadServicing) async {
        squad = try? await squadService.fetchCurrentSquad()
    }

    func signOut(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        try? await authService.signOut()
        router.handleSessionUpdate(nil)
    }
}
