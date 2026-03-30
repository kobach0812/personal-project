import AuthenticationServices
import CryptoKit
import Foundation
import Security

#if canImport(UIKit)
import UIKit
#endif

struct AppleSignInResult: Equatable, Sendable {
    let idToken: String
    let rawNonce: String
    let preferredName: String?
}

@MainActor
protocol AppleSignInProviding: AnyObject {
    func start() async throws -> AppleSignInResult
}

@MainActor
final class AppleSignInProvider: NSObject, AppleSignInProviding {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var rawNonce = ""

    func start() async throws -> AppleSignInResult {
        guard continuation == nil else {
            throw FirebaseIntegrationError.signInInProgress
        }

        rawNonce = randomNonceString()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            startRequest()
        }
    }

    private func startRequest() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish(with result: Result<AppleSignInResult, Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil

        switch result {
        case let .success(value):
            continuation.resume(returning: value)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }
}

extension AppleSignInProvider: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(FirebaseIntegrationError.invalidAppleCredential))
            return
        }

        guard let identityToken = credential.identityToken else {
            finish(with: .failure(FirebaseIntegrationError.missingIdentityToken))
            return
        }

        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            finish(with: .failure(FirebaseIntegrationError.invalidIdentityToken))
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let preferredName = credential.fullName
            .map { formatter.string(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }

        finish(
            with: .success(
                AppleSignInResult(
                    idToken: tokenString,
                    rawNonce: rawNonce,
                    preferredName: preferredName
                )
            )
        )
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(with: .failure(error))
    }
}

extension AppleSignInProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = windowScenes.flatMap(\.windows)

        if let keyWindow = windows.first(where: \.isKeyWindow) {
            return keyWindow
        }

        if let firstWindow = windows.first {
            return firstWindow
        }

        preconditionFailure("Apple sign-in requires an active window scene.")
        #else
        preconditionFailure("Apple sign-in requires a UIKit presentation anchor.")
        #endif
    }
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)

    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)

        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. OSStatus \(errorCode)")
        }

        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}
