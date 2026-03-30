import Foundation

enum FirebaseIntegrationError: LocalizedError {
    case sdkUnavailable(product: String)
    case notYetImplemented(feature: String)

    var errorDescription: String? {
        switch self {
        case let .sdkUnavailable(product):
            return "\(product) is not linked into the project yet."
        case let .notYetImplemented(feature):
            return "\(feature) is prepared in the architecture but not implemented yet."
        }
    }
}
