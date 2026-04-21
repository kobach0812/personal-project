import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebasePlayService: PlayServicing {
    private let authGateway: FirebaseAuthGateway

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    init(authGateway: FirebaseAuthGateway) {
        self.authGateway = authGateway
    }

    func fetchFeed() async throws -> [Play] {
        #if canImport(FirebaseFirestore)
        let (user, squadID) = try await requireUserAndSquad()

        let snapshot = try await firestore
            .collection(FirestorePaths.squadPlays(squadID))
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            play(from: doc.data(), playID: doc.documentID, squadID: squadID, currentUserID: user.id)
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func postPlay(mediaURL: URL, storagePath: String?, mediaType: MediaType, caption: String?) async throws -> Play {
        #if canImport(FirebaseFirestore)
        let (user, squadID) = try await requireUserAndSquad()

        let playID = UUID().uuidString
        var data: [String: Any] = [
            "id": playID,
            "squadID": squadID,
            "senderID": user.id,
            "senderName": user.displayName ?? "Player",
            "mediaType": mediaType.rawValue,
            "mediaURL": mediaURL.absoluteString,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let path = storagePath { data["storagePath"] = path }
        if let cap = caption, !cap.isEmpty { data["caption"] = cap }

        try await firestore.document(FirestorePaths.play(squadID, playID)).setData(data)

        return Play(
            id: playID,
            squadID: squadID,
            senderID: user.id,
            senderName: user.displayName ?? "Player",
            mediaType: mediaType,
            mediaURL: mediaURL,
            storagePath: storagePath,
            thumbnailURL: nil,
            caption: caption,
            durationSeconds: nil,
            reactionSummary: [:],
            currentUserReaction: nil,
            createdAt: .now
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func toggleReaction(for playID: String, emoji: String) async throws -> Play {
        #if canImport(FirebaseFirestore)
        let (user, squadID) = try await requireUserAndSquad()

        let playRef = firestore.document(FirestorePaths.play(squadID, playID))
        let snapshot = try await playRef.getDocument()

        guard let data = snapshot.data() else {
            throw PlayServiceError.notFound
        }

        var reactions = data["reactions"] as? [String: String] ?? [:]
        if reactions[user.id] == emoji {
            reactions.removeValue(forKey: user.id)
        } else {
            reactions[user.id] = emoji
        }

        try await playRef.updateData(["reactions": reactions])

        return play(from: data, playID: playID, squadID: squadID, currentUserID: user.id, reactions: reactions)
            ?? { throw PlayServiceError.notFound }()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }
}

private extension FirebasePlayService {
    func requireUserAndSquad() async throws -> (user: FirebaseAuthenticatedUser, squadID: String) {
        guard let user = try await authGateway.currentUser() else {
            throw PlayServiceError.notAuthenticated
        }

        #if canImport(FirebaseFirestore)
        let snapshot = try await firestore.document(FirestorePaths.user(user.id)).getDocument()
        guard let squadID = snapshot.data()?["squadID"] as? String else {
            throw PlayServiceError.noSquad
        }
        return (user, squadID)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    #if canImport(FirebaseFirestore)
    func play(
        from data: [String: Any],
        playID: String,
        squadID: String,
        currentUserID: String,
        reactions: [String: String]? = nil
    ) -> Play? {
        guard let mediaURLString = data["mediaURL"] as? String,
              let mediaURL = URL(string: mediaURLString) else { return nil }

        let reactionMap = reactions ?? (data["reactions"] as? [String: String] ?? [:])
        var summary: [String: Int] = [:]
        for (_, emoji) in reactionMap { summary[emoji, default: 0] += 1 }

        return Play(
            id: playID,
            squadID: squadID,
            senderID: data["senderID"] as? String ?? "",
            senderName: data["senderName"] as? String ?? "Player",
            mediaType: MediaType(rawValue: data["mediaType"] as? String ?? "") ?? .photo,
            mediaURL: mediaURL,
            storagePath: data["storagePath"] as? String,
            thumbnailURL: (data["thumbnailURL"] as? String).flatMap(URL.init),
            caption: data["caption"] as? String,
            durationSeconds: data["durationSeconds"] as? Int,
            reactionSummary: summary,
            currentUserReaction: reactionMap[currentUserID],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }
    #endif
}
