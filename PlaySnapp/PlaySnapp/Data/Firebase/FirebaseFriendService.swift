import Combine
import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseFriendService: FriendServicing {
    private let authGateway: FirebaseAuthGateway

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    init(authGateway: FirebaseAuthGateway) {
        self.authGateway = authGateway
    }

    func searchUsers(query: String) async throws -> [AppUser] {
        #if canImport(FirebaseFirestore)
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let end = trimmed + "\u{f8ff}"
        let snapshots = try await firestore
            .collection("users")
            .whereField("name", isGreaterThanOrEqualTo: trimmed)
            .whereField("name", isLessThanOrEqualTo: end)
            .limit(to: 20)
            .getDocuments()
        let myID = try await requireCurrentUser().id
        return snapshots.documents.compactMap { doc in
            guard doc.documentID != myID else { return nil }
            return appUser(from: doc.data(), userID: doc.documentID)
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func sendFriendRequest(to userID: String, fromName: String) async throws {
        #if canImport(FirebaseFirestore)
        let me = try await requireCurrentUser()
        let requestID = "\(me.id)_\(userID)"
        let data: [String: Any] = [
            "fromUserID": me.id,
            "toUserID": userID,
            "fromUserName": fromName,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        try await firestore.document(FirestorePaths.friendRequest(requestID)).setData(data)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func acceptFriendRequest(_ requestID: String) async throws {
        #if canImport(FirebaseFirestore)
        let me = try await requireCurrentUser()

        let reqDoc = try await firestore.document(FirestorePaths.friendRequest(requestID)).getDocument()
        guard let data = reqDoc.data(),
              let fromUserID = data["fromUserID"] as? String,
              let fromUserName = data["fromUserName"] as? String else { return }

        let myDoc = try await firestore.document(FirestorePaths.user(me.id)).getDocument()
        let myName = myDoc.data()?["name"] as? String ?? "Player"

        let batch = firestore.batch()
        batch.setData(
            ["id": fromUserID, "name": fromUserName],
            forDocument: firestore.document(FirestorePaths.friend(me.id, fromUserID))
        )
        batch.setData(
            ["id": me.id, "name": myName],
            forDocument: firestore.document(FirestorePaths.friend(fromUserID, me.id))
        )
        batch.deleteDocument(firestore.document(FirestorePaths.friendRequest(requestID)))
        try await batch.commit()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func declineFriendRequest(_ requestID: String) async throws {
        #if canImport(FirebaseFirestore)
        try await firestore.document(FirestorePaths.friendRequest(requestID)).delete()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchFriends() async throws -> [Friend] {
        #if canImport(FirebaseFirestore)
        let me = try await requireCurrentUser()
        let snapshots = try await firestore
            .collection(FirestorePaths.friends(me.id))
            .getDocuments()
        return snapshots.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String else { return nil }
            let avatarURL = (data["avatarURL"] as? String).flatMap(URL.init(string:))
            return Friend(id: doc.documentID, name: name, avatarURL: avatarURL)
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchPendingIncomingRequests() async throws -> [FriendRequest] {
        #if canImport(FirebaseFirestore)
        let me = try await requireCurrentUser()
        let snapshots = try await firestore
            .collection("friendRequests")
            .whereField("toUserID", isEqualTo: me.id)
            .getDocuments()
        return snapshots.documents.compactMap { doc in
            let data = doc.data()
            guard let fromUserID = data["fromUserID"] as? String,
                  let toUserID = data["toUserID"] as? String,
                  let fromUserName = data["fromUserName"] as? String else { return nil }
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
            return FriendRequest(
                id: doc.documentID,
                fromUserID: fromUserID,
                toUserID: toUserID,
                fromUserName: fromUserName,
                createdAt: createdAt
            )
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }
}

private extension FirebaseFriendService {
    func requireCurrentUser() async throws -> FirebaseAuthenticatedUser {
        guard let user = try await authGateway.currentUser() else {
            throw FriendServiceError.notAuthenticated
        }
        return user
    }

    func appUser(from data: [String: Any], userID: String) -> AppUser? {
        guard let name = data["name"] as? String, !name.isEmpty else { return nil }
        let avatarURL = (data["avatarURL"] as? String).flatMap(URL.init(string:))
        let activeSquadID = data["activeSquadID"] as? String ?? data["squadID"] as? String
        return AppUser(
            id: userID,
            name: name,
            avatarURL: avatarURL,
            activeSquadID: activeSquadID,
            createdAt: .now,
            updatedAt: .now
        )
    }
}
