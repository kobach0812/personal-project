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

    #if canImport(FirebaseAuth)
    func signIn(email: String, password: String) async throws -> FirebaseAuthenticatedUser {
        let result: AuthDataResult = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
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

    func createUser(email: String, password: String) async throws -> FirebaseAuthenticatedUser {
        let result: AuthDataResult = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
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

    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<String, Error>) in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) {
                verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let verificationID else {
                    continuation.resume(throwing: FirebaseIntegrationError.missingVerificationID)
                    return
                }

                continuation.resume(returning: verificationID)
            }
        }
    }

    func signIn(
        verificationID: String,
        verificationCode: String
    ) async throws -> FirebaseAuthenticatedUser {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        return try await signIn(with: credential)
    }
    #endif

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    #if canImport(FirebaseAuth)
    func signIn(with credential: AuthCredential) async throws -> FirebaseAuthenticatedUser {
        let result: AuthDataResult = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<AuthDataResult, Error>) in
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
