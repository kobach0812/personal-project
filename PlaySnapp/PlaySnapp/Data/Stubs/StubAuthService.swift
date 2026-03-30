import Foundation

actor StubAuthService: AuthServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func restoreSession() async throws -> AppSession? {
        await sessionStore.restoreSession()
    }

    func signIn(email: String, password: String) async throws -> AppSession {
        try await sessionStore.signIn(email: email, password: password)
    }

    func register(email: String, password: String) async throws -> AppSession {
        try await sessionStore.register(email: email, password: password)
    }

    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> String {
        await sessionStore.sendPhoneVerificationCode(to: phoneNumber)
    }

    func verifyPhoneNumber(code: String, verificationID: String) async throws -> AppSession {
        try await sessionStore.verifyPhoneNumber(code: code, verificationID: verificationID)
    }

    func signOut() async throws {
        await sessionStore.signOut()
    }
}
