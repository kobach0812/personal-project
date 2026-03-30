import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct FirebaseAuthenticatedUser: Equatable, Sendable {
    let id: String
    let displayName: String?
    let photoURL: URL?
}

actor FirebaseAuthGateway {
    func currentUser() throws -> FirebaseAuthenticatedUser? {
        #if canImport(FirebaseAuth)
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }

        return map(currentUser)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func updateCurrentUserDisplayName(_ name: String) async throws {
        #if canImport(FirebaseAuth)
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthServiceError.missingSession
        }

        let request = currentUser.createProfileChangeRequest()
        request.displayName = name

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            request.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    #if canImport(FirebaseAuth)
    func signIn(with credential: AuthCredential) async throws -> FirebaseAuthenticatedUser {
        let result = try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: FirebaseIntegrationError.missingAuthResult)
                    return
                }

                continuation.resume(returning: result)
            }
        }

        return map(result.user)
    }

    private func map(_ user: User) -> FirebaseAuthenticatedUser {
        FirebaseAuthenticatedUser(
            id: user.uid,
            displayName: user.displayName,
            photoURL: user.photoURL
        )
    }
    #endif
}
