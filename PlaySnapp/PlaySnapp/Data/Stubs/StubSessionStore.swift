import Foundation

actor StubSessionStore {
    private var session: AppSession?
    private var currentUser: AppUser?
    private var emailPasswords: [String: String] = [:]
    private var userIDsByIdentity: [String: String] = [:]
    private var pendingPhoneNumbersByVerificationID: [String: String] = [:]
    private let phoneVerificationCode = "123456"

    func restoreSession() -> AppSession? {
        session
    }

    func signIn(email: String, password: String) throws -> AppSession {
        let normalizedEmail = normalizeEmail(email)
        guard emailPasswords[normalizedEmail] == password else {
            throw AuthServiceError.invalidCredentials
        }

        return activateSession(forIdentity: normalizedEmail)
    }

    func register(email: String, password: String) throws -> AppSession {
        let normalizedEmail = normalizeEmail(email)
        guard emailPasswords[normalizedEmail] == nil else {
            throw AuthServiceError.accountAlreadyExists
        }

        emailPasswords[normalizedEmail] = password
        return activateSession(forIdentity: normalizedEmail)
    }

    func sendPhoneVerificationCode(to phoneNumber: String) -> String {
        let verificationID = UUID().uuidString
        pendingPhoneNumbersByVerificationID[verificationID] = normalizePhoneNumber(phoneNumber)
        return verificationID
    }

    func verifyPhoneNumber(code: String, verificationID: String) throws -> AppSession {
        guard code == phoneVerificationCode else {
            throw AuthServiceError.invalidVerificationCode
        }

        guard let phoneNumber = pendingPhoneNumbersByVerificationID.removeValue(
            forKey: verificationID
        ) else {
            throw AuthServiceError.missingPhoneVerification
        }

        return activateSession(forIdentity: phoneNumber)
    }

    func signOut() {
        session = nil
        currentUser = nil
    }

    func fetchCurrentUser() -> AppUser? {
        currentUser
    }

    func completeProfile(name: String) throws -> AppSession {
        guard var currentSession = session else {
            throw AuthServiceError.missingSession
        }

        currentSession.hasCompletedProfile = true
        session = currentSession

        let now = Date()
        currentUser = AppUser(
            id: currentSession.userID,
            name: name,
            avatarURL: currentUser?.avatarURL,
            squadID: currentUser?.squadID,
            createdAt: currentUser?.createdAt ?? now,
            updatedAt: now
        )

        return currentSession
    }

    func markJoinedSquad() throws -> AppSession {
        guard var currentSession = session else {
            throw AuthServiceError.missingSession
        }

        currentSession.hasJoinedSquad = true
        session = currentSession
        return currentSession
    }

    func markSeenWidgetIntro() throws -> AppSession {
        guard var currentSession = session else {
            throw AuthServiceError.missingSession
        }

        currentSession.hasSeenWidgetIntro = true
        session = currentSession
        return currentSession
    }

    func updateProfile(name: String) throws -> AppUser {
        guard var currentUser else {
            throw AuthServiceError.missingSession
        }

        currentUser.name = name
        currentUser.updatedAt = Date()
        self.currentUser = currentUser
        return currentUser
    }

    func updateAvatar(url: URL) throws -> AppUser {
        guard var currentUser else {
            throw AuthServiceError.missingSession
        }

        currentUser.avatarURL = url
        currentUser.updatedAt = Date()
        self.currentUser = currentUser
        return currentUser
    }

    func setCurrentSquad(id: String?) {
        guard var currentUser else {
            return
        }

        currentUser.squadID = id
        currentUser.updatedAt = Date()
        self.currentUser = currentUser
    }

    func currentUserID() -> String? {
        currentUser?.id ?? session?.userID
    }
}

private extension StubSessionStore {
    func activateSession(forIdentity identity: String) -> AppSession {
        let userID = userIDsByIdentity[identity] ?? UUID().uuidString
        let now = Date()

        userIDsByIdentity[identity] = userID

        let existingUser = currentUser?.id == userID ? currentUser : nil
        currentUser = AppUser(
            id: userID,
            name: existingUser?.name ?? "",
            avatarURL: existingUser?.avatarURL,
            squadID: existingUser?.squadID,
            createdAt: existingUser?.createdAt ?? now,
            updatedAt: now
        )

        let nextSession = AppSession(
            userID: userID,
            hasCompletedProfile: false,
            hasJoinedSquad: false,
            hasSeenWidgetIntro: false
        )
        session = nextSession
        return nextSession
    }

    func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func normalizePhoneNumber(_ phoneNumber: String) -> String {
        phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
