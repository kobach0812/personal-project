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
    func createSquad(name: String, sport: Sport) async throws -> Squad
    func joinSquad(inviteCode: String) async throws -> Squad
    func fetchCurrentSquad() async throws -> Squad?
}
