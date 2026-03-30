import Foundation

enum AuthServiceError: LocalizedError {
    case missingSession
    case invalidCredentials
    case accountAlreadyExists
    case missingPhoneVerification
    case invalidVerificationCode

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "You need to sign in before continuing."
        case .invalidCredentials:
            return "The email or password is incorrect."
        case .accountAlreadyExists:
            return "An account already exists with that email."
        case .missingPhoneVerification:
            return "Request a fresh phone verification code and try again."
        case .invalidVerificationCode:
            return "The verification code is invalid."
        }
    }
}

protocol AuthServicing {
    func restoreSession() async throws -> AppSession?
    func signIn(email: String, password: String) async throws -> AppSession
    func register(email: String, password: String) async throws -> AppSession
    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> String
    func verifyPhoneNumber(code: String, verificationID: String) async throws -> AppSession
    func signOut() async throws
}
