import Foundation

enum SquadServiceError: LocalizedError {
    case invalidInviteCode
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode: return "No squad found with that invite code."
        case .notAuthenticated: return "You must be signed in to manage squads."
        }
    }
}

protocol SquadServicing {
    func createSquad(name: String) async throws -> Squad
    func joinSquad(inviteCode: String) async throws -> Squad
    /// Returns the currently active squad (the one driving Feed / Camera / widget).
    func fetchCurrentSquad() async throws -> Squad?
    /// Returns all squads the current user belongs to.
    func fetchAllSquads() async throws -> [Squad]
    /// Changes which squad is active for the current user.
    func setActiveSquad(id: String) async throws
}
