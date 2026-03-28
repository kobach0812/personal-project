import Combine
import Foundation

@MainActor
final class WidgetIntroViewModel: ObservableObject {
    @Published var isSaving = false

    func finish(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        isSaving = true
        defer {
            isSaving = false
        }

        do {
            let session = try await authService.markSeenWidgetIntro()
            router.handleSessionUpdate(session)
        } catch {
            router.openMain()
        }
    }
}
