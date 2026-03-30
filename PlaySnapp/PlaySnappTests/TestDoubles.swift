import Foundation
@testable import PlaySnapp

enum TestFailure: Error, Sendable {
    case expected
}

func makeSession(
    hasCompletedProfile: Bool = true,
    hasJoinedSquad: Bool = true,
    hasSeenWidgetIntro: Bool = true
) -> AppSession {
    AppSession(
        userID: "test-user",
        hasCompletedProfile: hasCompletedProfile,
        hasJoinedSquad: hasJoinedSquad,
        hasSeenWidgetIntro: hasSeenWidgetIntro
    )
}

actor AuthServiceStub: AuthServicing {
    var restoredSession: AppSession?
    var restoreShouldFail = false

    init(restoredSession: AppSession? = nil) {
        self.restoredSession = restoredSession
    }

    func restoreSession() async throws -> AppSession? {
        if restoreShouldFail {
            throw TestFailure.expected
        }

        return restoredSession
    }

    func signIn(email: String, password: String) async throws -> AppSession {
        makeSession(hasCompletedProfile: false, hasJoinedSquad: false, hasSeenWidgetIntro: false)
    }

    func register(email: String, password: String) async throws -> AppSession {
        makeSession(hasCompletedProfile: false, hasJoinedSquad: false, hasSeenWidgetIntro: false)
    }

    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> String {
        "test-verification-id"
    }

    func verifyPhoneNumber(code: String, verificationID: String) async throws -> AppSession {
        makeSession(hasCompletedProfile: false, hasJoinedSquad: false, hasSeenWidgetIntro: false)
    }

    func signOut() async throws {}
}

actor OnboardingProgressServiceStub: OnboardingProgressServicing {
    var completeProfileSession = makeSession(hasJoinedSquad: false, hasSeenWidgetIntro: false)
    var joinedSquadSession = makeSession(hasSeenWidgetIntro: false)
    var seenWidgetIntroSession = makeSession()
    var shouldFailProfileSave = false
    var shouldFailJoin = false
    var shouldFailWidgetIntro = false

    func completeProfile(name: String, sport: Sport) async throws -> AppSession {
        if shouldFailProfileSave {
            throw TestFailure.expected
        }

        return completeProfileSession
    }

    func markJoinedSquad() async throws -> AppSession {
        if shouldFailJoin {
            throw TestFailure.expected
        }

        return joinedSquadSession
    }

    func markSeenWidgetIntro() async throws -> AppSession {
        if shouldFailWidgetIntro {
            throw TestFailure.expected
        }

        return seenWidgetIntroSession
    }
}

actor SquadServiceStub: SquadServicing {
    var createResult = Squad(
        id: "squad-1",
        name: "Tuesday Crew",
        sport: .football,
        memberIDs: ["test-user"],
        inviteCode: "PLAY1",
        createdAt: .now
    )
    var joinResult = Squad(
        id: "squad-2",
        name: "Join Crew",
        sport: .football,
        memberIDs: ["test-user"],
        inviteCode: "JOIN1",
        createdAt: .now
    )
    var shouldFailCreate = false
    var shouldFailJoin = false

    func createSquad(name: String, sport: Sport) async throws -> Squad {
        if shouldFailCreate {
            throw TestFailure.expected
        }

        return createResult
    }

    func joinSquad(inviteCode: String) async throws -> Squad {
        if shouldFailJoin {
            throw TestFailure.expected
        }

        return joinResult
    }

    func fetchCurrentSquad() async throws -> Squad? {
        createResult
    }
}
