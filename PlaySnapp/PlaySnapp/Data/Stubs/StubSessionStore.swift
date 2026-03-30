import Foundation

actor StubSessionStore {
    private var session: AppSession?
    private var currentUser: AppUser?

    func restoreSession() -> AppSession? {
        session
    }

    func signIn() -> AppSession {
        let userID = currentUser?.id ?? UUID().uuidString
        let now = Date()

        if currentUser == nil {
            currentUser = AppUser(
                id: userID,
                name: "",
                primarySport: .football,
                avatarURL: nil,
                squadID: nil,
                createdAt: now,
                updatedAt: now
            )
        }

        let nextSession = AppSession(
            userID: userID,
            hasCompletedProfile: false,
            hasJoinedSquad: false,
            hasSeenWidgetIntro: false
        )
        session = nextSession
        return nextSession
    }

    func signOut() {
        session = nil
        currentUser = nil
    }

    func fetchCurrentUser() -> AppUser? {
        currentUser
    }

    func completeProfile(name: String, sport: Sport) throws -> AppSession {
        guard var currentSession = session else {
            throw AuthServiceError.missingSession
        }

        currentSession.hasCompletedProfile = true
        session = currentSession

        let now = Date()
        currentUser = AppUser(
            id: currentSession.userID,
            name: name,
            primarySport: sport,
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
