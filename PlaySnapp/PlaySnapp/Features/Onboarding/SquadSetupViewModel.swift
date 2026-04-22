import Combine
import Foundation

enum SquadSetupMode: String, CaseIterable, Identifiable {
    case create
    case join

    var id: String { rawValue }

    var title: String {
        switch self {
        case .create:
            return "Create"
        case .join:
            return "Join"
        }
    }

    var sectionTitle: String {
        switch self {
        case .create:
            return "New squad"
        case .join:
            return "Invite code"
        }
    }

    var placeholder: String {
        switch self {
        case .create:
            return "Tuesday Crew"
        case .join:
            return "PLAY5"
        }
    }

    var buttonTitle: String {
        switch self {
        case .create:
            return "Create squad"
        case .join:
            return "Join squad"
        }
    }
}

@MainActor
final class SquadSetupViewModel: ObservableObject {
    @Published var mode: SquadSetupMode = .create
    @Published var input = ""
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var lastResolvedSquad: Squad?

    var canSubmit: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit(
        squadService: SquadServicing,
        progressService: OnboardingProgressServicing,
        router: AppRouter
    ) async {
        guard canSubmit else {
            errorMessage = "Enter a squad name or invite code."
            return
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

            let squad: Squad
            switch mode {
            case .create:
                squad = try await squadService.createSquad(name: normalizedInput)
            case .join:
                squad = try await squadService.joinSquad(inviteCode: normalizedInput)
            }

            lastResolvedSquad = squad
            let session = try await progressService.markJoinedSquad()
            router.handleSessionUpdate(session)
        } catch {
            errorMessage = "Could not complete squad setup."
        }
    }
}
