import Testing
@testable import PlaySnapp

@MainActor
struct OnboardingViewModelTests {
    @Test
    func profileSetupAdvancesRouterToSquadSetup() async {
        let viewModel = ProfileSetupViewModel()
        let router = AppRouter()
        let progressService = OnboardingProgressServiceStub()

        viewModel.name = "Andy"
        viewModel.selectedSport = .football

        await viewModel.saveProfile(
            progressService: progressService,
            router: router
        )

        #expect(router.phase == .squadSetup)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSaving == false)
    }

    @Test
    func squadSetupAdvancesRouterToWidgetIntro() async {
        let viewModel = SquadSetupViewModel()
        let router = AppRouter()
        let squadService = SquadServiceStub()
        let progressService = OnboardingProgressServiceStub()

        viewModel.mode = .create
        viewModel.input = "Tuesday Crew"

        await viewModel.submit(
            squadService: squadService,
            progressService: progressService,
            router: router
        )

        #expect(router.phase == .widgetIntro)
        #expect(viewModel.lastResolvedSquad?.name == "Tuesday Crew")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSaving == false)
    }

    @Test
    func widgetIntroAdvancesRouterToMain() async {
        let viewModel = WidgetIntroViewModel()
        let router = AppRouter()
        let progressService = OnboardingProgressServiceStub()

        await viewModel.finish(
            progressService: progressService,
            router: router
        )

        #expect(router.phase == .main)
        #expect(viewModel.isSaving == false)
    }
}
