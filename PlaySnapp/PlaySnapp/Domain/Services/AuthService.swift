import Foundation

enum AuthServiceError: Error {
    case missingSession
}

protocol AuthServicing {
    func restoreSession() async throws -> AppSession?
    func signInWithApple() async throws -> AppSession
    func signOut() async throws
}
