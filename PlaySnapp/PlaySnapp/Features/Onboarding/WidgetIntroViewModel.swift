import Combine
import Foundation

@MainActor
final class WidgetIntroViewModel: ObservableObject {
    @Published var isSaving = false

    func finish(
        progressService: OnboardingProgressServicing,
        router: AppRouter
    ) async {
        isSaving = true
        defer {
            isSaving = false
        }

        do {
            let session = try await progressService.markSeenWidgetIntro()
            router.handleSessionUpdate(session)
        } catch {
            router.openMain()
        }
    }
}
