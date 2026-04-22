import Combine
import Foundation

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var name = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveProfile(
        progressService: OnboardingProgressServicing,
        router: AppRouter
    ) async {
        guard canSubmit else {
            errorMessage = "Name is required."
            return
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let session = try await progressService.completeProfile(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            router.handleSessionUpdate(session)
        } catch {
            errorMessage = "Could not save the profile."
        }
    }
}
