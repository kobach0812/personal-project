import Foundation

enum FriendServiceError: LocalizedError {
    case notAuthenticated
    case requestAlreadyExists
    case requestNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in."
        case .requestAlreadyExists: return "Friend request already sent."
        case .requestNotFound: return "Friend request not found."
        }
    }
}

protocol FriendServicing {
    /// Search users by display name. Excludes the current user.
    func searchUsers(query: String) async throws -> [AppUser]
    /// Sends a friend request from the current user to `userID`.
    func sendFriendRequest(to userID: String, fromName: String) async throws
    /// Accepts an incoming request and adds both users as friends.
    func acceptFriendRequest(_ requestID: String) async throws
    /// Declines and deletes an incoming request.
    func declineFriendRequest(_ requestID: String) async throws
    /// Returns all confirmed friends of the current user.
    func fetchFriends() async throws -> [Friend]
    /// Returns pending incoming requests addressed to the current user.
    func fetchPendingIncomingRequests() async throws -> [FriendRequest]
}
