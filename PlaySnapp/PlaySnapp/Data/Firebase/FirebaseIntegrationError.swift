import Foundation

enum FirebaseIntegrationError: LocalizedError {
    case sdkUnavailable(product: String)
    case notYetImplemented(feature: String)
    case signInInProgress
    case missingIdentityToken
    case invalidIdentityToken
    case invalidAppleCredential
    case missingAuthResult
    case missingVerificationID

    var errorDescription: String? {
        switch self {
        case let .sdkUnavailable(product):
            return "\(product) is not linked into the project yet."
        case let .notYetImplemented(feature):
            return "\(feature) is prepared in the architecture but not implemented yet."
        case .signInInProgress:
            return "Apple sign-in is already in progress."
        case .missingIdentityToken:
            return "Apple sign-in did not return an identity token."
        case .invalidIdentityToken:
            return "Apple sign-in returned an invalid identity token."
        case .invalidAppleCredential:
            return "Apple sign-in returned an unexpected credential type."
        case .missingAuthResult:
            return "Firebase Auth did not return a user session."
        case .missingVerificationID:
            return "Firebase Phone Auth did not return a verification ID."
        }
    }
}
