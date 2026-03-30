import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

actor FirebaseAuthService: AuthServicing {
    func restoreSession() async throws -> AppSession? {
        #if canImport(FirebaseAuth)
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }

        return AppSession(
            userID: currentUser.uid,
            hasCompletedProfile: false,
            hasJoinedSquad: false,
            hasSeenWidgetIntro: false
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }

    func signInWithApple() async throws -> AppSession {
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Sign in with Apple credential exchange via Firebase Auth"
        )
    }

    func completeProfile(name: String, sport: Sport) async throws -> AppSession {
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Profile persistence to Firestore"
        )
    }

    func markJoinedSquad() async throws -> AppSession {
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Squad membership persistence to Firestore"
        )
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Widget onboarding state persistence"
        )
    }

    func signOut() async throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseAuth")
        #endif
    }
}
