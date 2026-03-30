import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseSessionDocumentStore {
    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    func fetchOrCreateSession(
        for user: FirebaseAuthenticatedUser,
        preferredName: String? = nil
    ) async throws -> AppSession {
        let document = try await fetchOrCreateUserDocument(for: user, preferredName: preferredName)
        return session(from: document, userID: user.id)
    }

    func completeProfile(
        userID: String,
        name: String,
        sport: Sport
    ) async throws -> AppSession {
        let document = try await mergeDocument(
            fields: [
                "name": name,
                "primarySport": sport.rawValue,
                "hasCompletedProfile": true,
            ],
            for: userID
        )

        return session(from: document, userID: userID)
    }

    func markJoinedSquad(userID: String) async throws -> AppSession {
        let document = try await mergeDocument(
            fields: [
                "hasJoinedSquad": true,
            ],
            for: userID
        )

        return session(from: document, userID: userID)
    }

    func markSeenWidgetIntro(userID: String) async throws -> AppSession {
        let document = try await mergeDocument(
            fields: [
                "hasSeenWidgetIntro": true,
            ],
            for: userID
        )

        return session(from: document, userID: userID)
    }

    func fetchCurrentUser(for user: FirebaseAuthenticatedUser) async throws -> AppUser {
        let document = try await fetchOrCreateUserDocument(for: user, preferredName: user.displayName)
        return appUser(from: document, fallbackUser: user)
    }
}

private extension FirebaseSessionDocumentStore {
    func fetchOrCreateUserDocument(
        for user: FirebaseAuthenticatedUser,
        preferredName: String?
    ) async throws -> [String: Any] {
        #if canImport(FirebaseFirestore)
        let reference = userDocumentReference(for: user.id)
        let snapshot = try await reference.getDocument()

        if let existing = snapshot.data() {
            return existing
        }

        let baseDocument = makeBaseUserDocument(for: user, preferredName: preferredName)
        try await reference.setData(baseDocument, merge: true)
        return baseDocument
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func mergeDocument(
        fields: [String: Any],
        for userID: String
    ) async throws -> [String: Any] {
        #if canImport(FirebaseFirestore)
        let reference = userDocumentReference(for: userID)
        var updatedFields = fields
        updatedFields["updatedAt"] = Date()

        try await reference.setData(updatedFields, merge: true)

        let snapshot = try await reference.getDocument()
        return snapshot.data() ?? updatedFields
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func session(from data: [String: Any], userID: String) -> AppSession {
        AppSession(
            userID: userID,
            hasCompletedProfile: data["hasCompletedProfile"] as? Bool ?? false,
            hasJoinedSquad: data["hasJoinedSquad"] as? Bool ?? false,
            hasSeenWidgetIntro: data["hasSeenWidgetIntro"] as? Bool ?? false
        )
    }

    func appUser(
        from data: [String: Any],
        fallbackUser: FirebaseAuthenticatedUser
    ) -> AppUser {
        let rawName = data["name"] as? String
        let resolvedName = rawName?.isEmpty == false ? rawName : fallbackUser.displayName
        let rawSport = data["primarySport"] as? String
        let avatarString = data["avatarURL"] as? String ?? fallbackUser.photoURL?.absoluteString
        let createdAt = data["createdAt"] as? Date ?? .now
        let updatedAt = data["updatedAt"] as? Date ?? createdAt

        return AppUser(
            id: fallbackUser.id,
            name: resolvedName ?? "Player",
            primarySport: Sport(rawValue: rawSport ?? "") ?? .football,
            avatarURL: avatarString.flatMap(URL.init(string:)),
            squadID: data["squadID"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func makeBaseUserDocument(
        for user: FirebaseAuthenticatedUser,
        preferredName: String?
    ) -> [String: Any] {
        var data: [String: Any] = [
            "hasCompletedProfile": false,
            "hasJoinedSquad": false,
            "hasSeenWidgetIntro": false,
            "createdAt": Date(),
            "updatedAt": Date(),
        ]

        if let preferredName, !preferredName.isEmpty {
            data["name"] = preferredName
        }

        if let avatarURL = user.photoURL?.absoluteString {
            data["avatarURL"] = avatarURL
        }

        return data
    }

    #if canImport(FirebaseFirestore)
    func userDocumentReference(for userID: String) -> DocumentReference {
        firestore.document(FirestorePaths.user(userID))
    }
    #endif
}
