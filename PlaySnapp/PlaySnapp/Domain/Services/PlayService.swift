import Foundation

protocol PlayServicing {
    func fetchFeed() async throws -> [Play]
    func toggleReaction(for playID: String, emoji: String) async throws -> [Play]
}
