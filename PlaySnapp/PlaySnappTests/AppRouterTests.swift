import Testing
@testable import PlaySnapp

@MainActor
struct AppRouterTests {
    @Test
    func bootstrapRoutesToAuthWhenThereIsNoSession() async {
        let router = AppRouter()
        let authService = AuthServiceStub()

        await router.bootstrap(using: authService)

        #expect(router.phase == .auth)
    }

    @Test
    func bootstrapRoutesToProfileSetupForIncompleteSession() async {
        let router = AppRouter()
        let authService = AuthServiceStub(
            restoredSession: makeSession(
                hasCompletedProfile: false,
                hasJoinedSquad: false,
                hasSeenWidgetIntro: false
            )
        )

        await router.bootstrap(using: authService)

        #expect(router.phase == .profileSetup)
    }

    @Test
    func handleSessionUpdateRoutesThroughOnboardingPhases() {
        let router = AppRouter()

        router.handleSessionUpdate(makeSession(hasJoinedSquad: false, hasSeenWidgetIntro: false))
        #expect(router.phase == .squadSetup)

        router.handleSessionUpdate(makeSession(hasSeenWidgetIntro: false))
        #expect(router.phase == .widgetIntro)

        router.handleSessionUpdate(makeSession())
        #expect(router.phase == .main)
    }
}
