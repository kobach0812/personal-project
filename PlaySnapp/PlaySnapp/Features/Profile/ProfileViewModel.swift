import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var allSquads: [Squad] = []
    @Published var isLoading = false

    // Profile edit sheet state
    @Published var isEditingProfile = false
    @Published var editName = ""
    @Published var isSaving = false
    @Published var saveError: String?

    // Add-squad sheet state
    @Published var isAddingSquad = false
    @Published var addSquadMode: SquadSetupMode = .create
    @Published var addSquadInput = ""
    @Published var isAddingSquadSaving = false
    @Published var addSquadError: String?

    func load(
        profileService: UserProfileServicing,
        squadService: SquadServicing
    ) async {
        isLoading = true
        defer { isLoading = false }

        async let loadedUser = profileService.fetchCurrentUser()
        async let loadedSquads = squadService.fetchAllSquads()

        do { user = try await loadedUser } catch { user = nil }
        do { allSquads = try await loadedSquads } catch { allSquads = [] }
    }

    // MARK: Profile edit

    func startEditing() {
        editName = user?.name ?? ""
        saveError = nil
        isEditingProfile = true
    }

    func saveProfile(profileService: UserProfileServicing) async {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            user = try await profileService.updateProfile(name: trimmed)
            isEditingProfile = false
        } catch {
            saveError = error.localizedDescription
        }
    }

    // MARK: Squad management

    func switchSquad(to squad: Squad, squadService: SquadServicing) async {
        do {
            try await squadService.setActiveSquad(id: squad.id)
            user?.activeSquadID = squad.id
        } catch {
            // silent — the UI still reflects the tap optimistically
        }
    }

    func addSquad(squadService: SquadServicing) async {
        let trimmed = addSquadInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isAddingSquadSaving = true
        addSquadError = nil
        defer { isAddingSquadSaving = false }
        do {
            let squad: Squad
            switch addSquadMode {
            case .create: squad = try await squadService.createSquad(name: trimmed)
            case .join:   squad = try await squadService.joinSquad(inviteCode: trimmed)
            }
            if !allSquads.contains(where: { $0.id == squad.id }) {
                allSquads.append(squad)
            }
            user?.activeSquadID = squad.id
            isAddingSquad = false
            addSquadInput = ""
        } catch {
            addSquadError = error.localizedDescription
        }
    }

    // MARK: Sign out

    func signOut(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        try? await authService.signOut()
        router.handleSessionUpdate(nil)
    }
}
