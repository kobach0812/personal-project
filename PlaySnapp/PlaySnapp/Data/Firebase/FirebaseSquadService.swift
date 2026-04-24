import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

actor FirebaseSquadService: SquadServicing {
    private let authGateway: FirebaseAuthGateway

    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    init(authGateway: FirebaseAuthGateway) {
        self.authGateway = authGateway
    }

    func createSquad(name: String) async throws -> Squad {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let squadID = UUID().uuidString
        let inviteCode = Self.generateInviteCode()

        let squadData: [String: Any] = [
            "id": squadID,
            "name": name,
            "createdBy": user.id,
            "memberIDs": [user.id],
            "inviteCode": inviteCode,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        let batch = firestore.batch()
        batch.setData(squadData, forDocument: firestore.document(FirestorePaths.squad(squadID)))
        batch.setData(
            [
                "squadIDs": FieldValue.arrayUnion([squadID]),
                "activeSquadID": squadID,
            ],
            forDocument: firestore.document(FirestorePaths.user(user.id)),
            merge: true
        )
        try await batch.commit()

        return Squad(
            id: squadID,
            name: name,
            createdBy: user.id,
            memberIDs: [user.id],
            inviteCode: inviteCode,
            createdAt: .now
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func joinSquad(inviteCode: String) async throws -> Squad {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let results = try await firestore
            .collection("squads")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
            .limit(to: 1)
            .getDocuments()

        guard let document = results.documents.first else {
            throw SquadServiceError.invalidInviteCode
        }

        let squadID = document.documentID
        let data = document.data()

        let batch = firestore.batch()
        batch.updateData(
            ["memberIDs": FieldValue.arrayUnion([user.id])],
            forDocument: firestore.document(FirestorePaths.squad(squadID))
        )
        batch.setData(
            [
                "squadIDs": FieldValue.arrayUnion([squadID]),
                "activeSquadID": squadID,
            ],
            forDocument: firestore.document(FirestorePaths.user(user.id)),
            merge: true
        )
        try await batch.commit()

        return Self.squad(from: data, squadID: squadID, appendingMemberID: user.id)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchCurrentSquad() async throws -> Squad? {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let userSnapshot = try await firestore.document(FirestorePaths.user(user.id)).getDocument()
        let userData = userSnapshot.data() ?? [:]
        // Read activeSquadID; fall back to legacy squadID field for existing documents
        guard let squadID = userData["activeSquadID"] as? String ?? userData["squadID"] as? String else {
            return nil
        }

        let squadSnapshot = try await firestore.document(FirestorePaths.squad(squadID)).getDocument()
        guard let data = squadSnapshot.data() else { return nil }
        return Self.squad(from: data, squadID: squadID)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchAllSquads() async throws -> [Squad] {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let userSnapshot = try await firestore.document(FirestorePaths.user(user.id)).getDocument()
        let userData = userSnapshot.data() ?? [:]

        var squadIDs = userData["squadIDs"] as? [String] ?? []
        // Include legacy single squadID field during migration
        if let legacyID = userData["squadID"] as? String, !squadIDs.contains(legacyID) {
            squadIDs.append(legacyID)
        }

        guard !squadIDs.isEmpty else { return [] }

        // Fetch all squad docs concurrently
        return try await withThrowingTaskGroup(of: Squad?.self) { group in
            for id in squadIDs {
                group.addTask {
                    let snap = try await self.firestore.document(FirestorePaths.squad(id)).getDocument()
                    guard let data = snap.data() else { return nil }
                    return Self.squad(from: data, squadID: id)
                }
            }
            var result: [Squad] = []
            for try await squad in group {
                if let squad { result.append(squad) }
            }
            return result.sorted { $0.createdAt < $1.createdAt }
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func setActiveSquad(id: String) async throws {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()
        try await firestore.document(FirestorePaths.user(user.id)).setData(
            ["activeSquadID": id],
            merge: true
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }
}

private extension FirebaseSquadService {
    func requireCurrentUser() async throws -> FirebaseAuthenticatedUser {
        guard let user = try await authGateway.currentUser() else {
            throw SquadServiceError.notAuthenticated
        }
        return user
    }

    // Removes ambiguous characters (0/O, 1/I) to avoid user confusion.
    static func generateInviteCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    #if canImport(FirebaseFirestore)
    nonisolated static func squad(from data: [String: Any], squadID: String, appendingMemberID: String? = nil) -> Squad {
        var memberIDs = data["memberIDs"] as? [String] ?? []
        if let extra = appendingMemberID, !memberIDs.contains(extra) {
            memberIDs.append(extra)
        }
        return Squad(
            id: squadID,
            name: data["name"] as? String ?? "Squad",
            createdBy: data["createdBy"] as? String ?? "",
            memberIDs: memberIDs,
            inviteCode: data["inviteCode"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }
    #endif
}
