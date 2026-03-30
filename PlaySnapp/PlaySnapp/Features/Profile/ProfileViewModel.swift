import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var squad: Squad?
    @Published var isLoading = false

    func load(
        profileService: UserProfileServicing,
        squadService: SquadServicing
    ) async {
        isLoading = true
        defer {
            isLoading = false
        }

        async let loadedUser = profileService.fetchCurrentUser()
        async let loadedSquad = squadService.fetchCurrentSquad()

        do {
            user = try await loadedUser
        } catch {
            user = nil
        }

        do {
            squad = try await loadedSquad
        } catch {
            squad = nil
        }
    }

    func signOut(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        try? await authService.signOut()
        router.handleSessionUpdate(nil)
    }
}
