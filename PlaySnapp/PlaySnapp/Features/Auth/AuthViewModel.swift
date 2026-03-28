import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func continueWithApple(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let session = try await authService.signInWithApple()
            router.handleSessionUpdate(session)
        } catch {
            errorMessage = "Sign in failed. Wire this screen to Firebase Auth next."
        }
    }
}
