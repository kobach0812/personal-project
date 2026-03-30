import Foundation

actor StubAuthService: AuthServicing {
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func restoreSession() async throws -> AppSession? {
        await sessionStore.restoreSession()
    }

    func signInWithApple() async throws -> AppSession {
        await sessionStore.signIn()
    }

    func signOut() async throws {
        await sessionStore.signOut()
    }
}
