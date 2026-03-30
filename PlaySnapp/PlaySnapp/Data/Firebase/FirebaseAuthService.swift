import AuthenticationServices
import CryptoKit
import Foundation
import Security

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#if canImport(UIKit)
import UIKit
#endif

actor FirebaseAuthService: AuthServicing {
    #if canImport(FirebaseFirestore)
    private let firestore = Firestore.firestore()
    #endif

    func restoreSession() async throws -> AppSession? {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }

        let document = try await fetchOrCreateUserDocument(for: currentUser)
        return session(from: document, userID: currentUser.uid)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth/FirebaseFirestore")
        #endif
    }

    func signInWithApple() async throws -> AppSession {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let appleSignIn = try await AppleSignInCoordinator.start()
        let credential = OAuthProvider.appleCredential(
            withIDToken: appleSignIn.idToken,
            rawNonce: appleSignIn.rawNonce,
            fullName: appleSignIn.fullName
        )

        let result = try await signIn(with: credential)
        let user = result.user
        let reference = firestore.document(FirestorePaths.user(user.uid))
        let snapshot = try await reference.getDocument()

        if let existing = snapshot.data() {
            return session(from: existing, userID: user.uid)
        }

        let baseDocument = makeBaseUserDocument(
            user: user,
            preferredName: appleSignIn.formattedName
        )
        try await reference.setData(baseDocument, merge: true)

        return session(from: baseDocument, userID: user.uid)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth/FirebaseFirestore")
        #endif
    }

    func completeProfile(name: String, sport: Sport) async throws -> AppSession {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let currentUser = try requireCurrentUser()

        try await updateDisplayName(name, for: currentUser)

        let reference = firestore.document(FirestorePaths.user(currentUser.uid))
        try await reference.setData(
            [
                "name": name,
                "primarySport": sport.rawValue,
                "hasCompletedProfile": true,
                "updatedAt": Date(),
            ],
            merge: true
        )

        let document = try await fetchOrCreateUserDocument(for: currentUser)
        return session(from: document, userID: currentUser.uid)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth/FirebaseFirestore")
        #endif
    }

    func markJoinedSquad() async throws -> AppSession {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let currentUser = try requireCurrentUser()
        let reference = firestore.document(FirestorePaths.user(currentUser.uid))

        try await reference.setData(
            [
                "hasJoinedSquad": true,
                "updatedAt": Date(),
            ],
            merge: true
        )

        let document = try await fetchOrCreateUserDocument(for: currentUser)
        return session(from: document, userID: currentUser.uid)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth/FirebaseFirestore")
        #endif
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let currentUser = try requireCurrentUser()
        let reference = firestore.document(FirestorePaths.user(currentUser.uid))

        try await reference.setData(
            [
                "hasSeenWidgetIntro": true,
                "updatedAt": Date(),
            ],
            merge: true
        )

        let document = try await fetchOrCreateUserDocument(for: currentUser)
        return session(from: document, userID: currentUser.uid)
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth/FirebaseFirestore")
        #endif
    }

    func signOut() async throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }
}

private extension FirebaseAuthService {
    #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
    func requireCurrentUser() throws -> User {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthServiceError.missingSession
        }

        return currentUser
    }

    func fetchOrCreateUserDocument(for user: User) async throws -> [String: Any] {
        let reference = firestore.document(FirestorePaths.user(user.uid))
        let snapshot = try await reference.getDocument()

        if let existing = snapshot.data() {
            return existing
        }

        let baseDocument = makeBaseUserDocument(user: user, preferredName: user.displayName)
        try await reference.setData(baseDocument, merge: true)
        return baseDocument
    }

    func makeBaseUserDocument(user: User, preferredName: String?) -> [String: Any] {
        var data: [String: Any] = [
            "hasCompletedProfile": false,
            "hasJoinedSquad": false,
            "hasSeenWidgetIntro": false,
            "createdAt": Date(),
            "updatedAt": Date(),
        ]

        if let preferredName, !preferredName.isEmpty {
            data["name"] = preferredName
        }

        if let avatarURL = user.photoURL?.absoluteString {
            data["avatarURL"] = avatarURL
        }

        return data
    }

    func session(from data: [String: Any], userID: String) -> AppSession {
        AppSession(
            userID: userID,
            hasCompletedProfile: data["hasCompletedProfile"] as? Bool ?? false,
            hasJoinedSquad: data["hasJoinedSquad"] as? Bool ?? false,
            hasSeenWidgetIntro: data["hasSeenWidgetIntro"] as? Bool ?? false
        )
    }

    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
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
    }

    func updateDisplayName(_ name: String, for user: User) async throws {
        let request = user.createProfileChangeRequest()
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
    }
    #endif
}

@MainActor
private final class AppleSignInCoordinator: NSObject {
    private static var activeCoordinator: AppleSignInCoordinator?

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private let rawNonce: String

    private init(rawNonce: String) {
        self.rawNonce = rawNonce
    }

    static func start() async throws -> AppleSignInResult {
        let nonce = randomNonceString()
        let coordinator = AppleSignInCoordinator(rawNonce: nonce)
        activeCoordinator = coordinator

        return try await withCheckedThrowingContinuation { continuation in
            coordinator.continuation = continuation
            coordinator.startRequest()
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
            Self.activeCoordinator = nil
            return
        }

        self.continuation = nil
        Self.activeCoordinator = nil

        switch result {
        case let .success(value):
            continuation.resume(returning: value)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
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

        let result = AppleSignInResult(
            idToken: tokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )
        finish(with: .success(result))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(with: .failure(error))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? UIWindow(frame: .zero)
        #else
        return ASPresentationAnchor()
        #endif
    }
}

private struct AppleSignInResult {
    let idToken: String
    let rawNonce: String
    let fullName: PersonNameComponents?

    var formattedName: String? {
        guard let fullName else {
            return nil
        }

        let formatter = PersonNameComponentsFormatter()
        let value = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
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
