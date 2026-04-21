import Foundation

enum PlayServiceError: LocalizedError {
    case notFound
    case notAuthenticated
    case noSquad

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The play could not be found."
        case .notAuthenticated:
            return "You must be signed in to post."
        case .noSquad:
            return "You are not in a squad."
        }
    }
}

protocol PlayServicing {
    func fetchFeed() async throws -> [Play]
    func postPlay(mediaURL: URL, storagePath: String?, mediaType: MediaType, caption: String?) async throws -> Play
    /// Toggles the given emoji reaction for the current user and returns the updated play.
    /// Callers are responsible for replacing the play in their local list.
    func toggleReaction(for playID: String, emoji: String) async throws -> Play
}
