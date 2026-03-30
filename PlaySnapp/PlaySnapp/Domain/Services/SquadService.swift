import Foundation

protocol SquadServicing {
    func createSquad(name: String, sport: Sport) async throws -> Squad
    func joinSquad(inviteCode: String) async throws -> Squad
    func fetchCurrentSquad() async throws -> Squad?
}
