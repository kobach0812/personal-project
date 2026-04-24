import Foundation

actor StubFriendService: FriendServicing {
    private let sessionStore: StubSessionStore
    private var friends: [Friend] = []
    private var incomingRequests: [FriendRequest] = []
    private var sentRequestIDs: Set<String> = []

    init(sessionStore: StubSessionStore) {
        self.sessionStore = sessionStore
    }

    // Canned users available for search in development / previews.
    private static let fakeUsers: [AppUser] = [
        AppUser(id: "stub-u1", name: "Jordan Lee",   avatarURL: nil, activeSquadID: nil, createdAt: .now, updatedAt: .now),
        AppUser(id: "stub-u2", name: "Alex Kim",     avatarURL: nil, activeSquadID: nil, createdAt: .now, updatedAt: .now),
        AppUser(id: "stub-u3", name: "Sam Rivera",   avatarURL: nil, activeSquadID: nil, createdAt: .now, updatedAt: .now),
        AppUser(id: "stub-u4", name: "Maya Patel",   avatarURL: nil, activeSquadID: nil, createdAt: .now, updatedAt: .now),
        AppUser(id: "stub-u5", name: "Chris Taylor", avatarURL: nil, activeSquadID: nil, createdAt: .now, updatedAt: .now),
    ]

    func searchUsers(query: String) async throws -> [AppUser] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let myID = await sessionStore.currentUserID()
        return Self.fakeUsers.filter {
            $0.id != myID && $0.name.lowercased().contains(trimmed)
        }
    }

    func sendFriendRequest(to userID: String, fromName: String) async throws {
        let myID = await sessionStore.currentUserID() ?? "me"
        let requestID = "\(myID)_\(userID)"
        guard !sentRequestIDs.contains(requestID) else {
            throw FriendServiceError.requestAlreadyExists
        }
        sentRequestIDs.insert(requestID)
        // Simulate the request appearing as an incoming request (for demo purposes).
        let req = FriendRequest(
            id: requestID,
            fromUserID: myID,
            toUserID: userID,
            fromUserName: fromName,
            createdAt: .now
        )
        incomingRequests.append(req)
    }

    func acceptFriendRequest(_ requestID: String) async throws {
        guard let req = incomingRequests.first(where: { $0.id == requestID }) else {
            throw FriendServiceError.requestNotFound
        }
        incomingRequests.removeAll { $0.id == requestID }
        friends.append(Friend(id: req.fromUserID, name: req.fromUserName, avatarURL: nil))
    }

    func declineFriendRequest(_ requestID: String) async throws {
        guard incomingRequests.contains(where: { $0.id == requestID }) else {
            throw FriendServiceError.requestNotFound
        }
        incomingRequests.removeAll { $0.id == requestID }
    }

    func fetchFriends() async throws -> [Friend] {
        friends
    }

    func fetchPendingIncomingRequests() async throws -> [FriendRequest] {
        incomingRequests
    }
}
