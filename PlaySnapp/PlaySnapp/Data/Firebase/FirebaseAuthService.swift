import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

actor FirebaseAuthService: AuthServicing {
    private let authGateway: FirebaseAuthGateway
    private let sessionStore: FirebaseSessionDocumentStore

    init(
        authGateway: FirebaseAuthGateway = FirebaseAuthGateway(),
        sessionStore: FirebaseSessionDocumentStore = FirebaseSessionDocumentStore()
    ) {
        self.authGateway = authGateway
        self.sessionStore = sessionStore
    }

    func restoreSession() async throws -> AppSession? {
        guard let currentUser = try await authGateway.currentUser() else {
            return nil
        }

        return try await sessionStore.fetchOrCreateSession(for: currentUser)
    }

    func signInWithApple() async throws -> AppSession {
        #if canImport(FirebaseAuth)
        let appleSignIn = try await startAppleSignIn()
        let credential = OAuthProvider.appleCredential(
            withIDToken: appleSignIn.idToken,
            rawNonce: appleSignIn.rawNonce,
            fullName: nil
        )
        let user = try await authGateway.signIn(with: credential)
        return try await sessionStore.fetchOrCreateSession(
            for: user,
            preferredName: appleSignIn.preferredName
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func signOut() async throws {
        try await authGateway.signOut()
    }
}

private extension FirebaseAuthService {
    @MainActor
    func startAppleSignIn() async throws -> AppleSignInResult {
        let provider = AppleSignInProvider()
        return try await provider.start()
    }
}
