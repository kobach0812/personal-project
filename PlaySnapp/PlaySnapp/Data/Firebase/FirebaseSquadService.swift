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

    func createSquad(name: String, sport: Sport) async throws -> Squad {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let squadID = UUID().uuidString
        let inviteCode = Self.generateInviteCode()

        let squadData: [String: Any] = [
            "id": squadID,
            "name": name,
            "sport": sport.rawValue,
            "createdBy": user.id,
            "memberIDs": [user.id],
            "inviteCode": inviteCode,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        let batch = firestore.batch()
        batch.setData(squadData, forDocument: firestore.document(FirestorePaths.squad(squadID)))
        batch.setData(["squadID": squadID], forDocument: firestore.document(FirestorePaths.user(user.id)), merge: true)
        try await batch.commit()

        return Squad(
            id: squadID,
            name: name,
            sport: sport,
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
            ["squadID": squadID],
            forDocument: firestore.document(FirestorePaths.user(user.id)),
            merge: true
        )
        try await batch.commit()

        return squad(from: data, squadID: squadID, appendingMemberID: user.id)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseFirestore")
        #endif
    }

    func fetchCurrentSquad() async throws -> Squad? {
        #if canImport(FirebaseFirestore)
        let user = try await requireCurrentUser()

        let userSnapshot = try await firestore.document(FirestorePaths.user(user.id)).getDocument()
        guard let squadID = userSnapshot.data()?["squadID"] as? String else {
            return nil
        }

        let squadSnapshot = try await firestore.document(FirestorePaths.squad(squadID)).getDocument()
        guard let data = squadSnapshot.data() else {
            return nil
        }

        return squad(from: data, squadID: squadID)
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
    func squad(from data: [String: Any], squadID: String, appendingMemberID: String? = nil) -> Squad {
        var memberIDs = data["memberIDs"] as? [String] ?? []
        if let extra = appendingMemberID, !memberIDs.contains(extra) {
            memberIDs.append(extra)
        }

        return Squad(
            id: squadID,
            name: data["name"] as? String ?? "Squad",
            sport: Sport(rawValue: data["sport"] as? String ?? "") ?? .football,
            createdBy: data["createdBy"] as? String ?? "",
            memberIDs: memberIDs,
            inviteCode: data["inviteCode"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }
    #endif
}
