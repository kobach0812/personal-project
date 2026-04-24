import Foundation

/// A confirmed mutual connection. Stored at `users/{uid}/friends/{friendID}`.
struct Friend: Identifiable, Codable, Equatable, Sendable {
    let id: String      // the other user's UID
    var name: String
    var avatarURL: URL?
}

/// A pending friend request. Stored at `friendRequests/{fromUID_toUID}`.
struct FriendRequest: Identifiable, Codable, Equatable, Sendable {
    let id: String              // "\(fromUserID)_\(toUserID)"
    let fromUserID: String
    let toUserID: String
    var fromUserName: String
    let createdAt: Date
}
