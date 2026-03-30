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

    func signIn(email: String, password: String) async throws -> AppSession {
        #if canImport(FirebaseAuth)
        let user = try await authGateway.signIn(email: email, password: password)
        return try await sessionStore.fetchOrCreateSession(for: user, preferredName: user.displayName)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func register(email: String, password: String) async throws -> AppSession {
        #if canImport(FirebaseAuth)
        let user = try await authGateway.createUser(email: email, password: password)
        return try await sessionStore.fetchOrCreateSession(for: user, preferredName: user.displayName)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> String {
        #if canImport(FirebaseAuth)
        return try await authGateway.sendPhoneVerificationCode(to: phoneNumber)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func verifyPhoneNumber(
        code: String,
        verificationID: String
    ) async throws -> AppSession {
        #if canImport(FirebaseAuth)
        let user = try await authGateway.signIn(
            verificationID: verificationID,
            verificationCode: code
        )
        return try await sessionStore.fetchOrCreateSession(for: user, preferredName: user.displayName)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func signOut() async throws {
        try await authGateway.signOut()
    }
}
