import SwiftUI

@main
struct PlaySnapApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var environment = AppEnvironment.bootstrap(dataSource: .firebasePrepared)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(environment)
                .task {
                    await router.bootstrap(using: environment.authService)
                    // Attempt device registration once we know the user is authenticated.
                    // Fails silently if the user is not signed in or permissions are not granted yet.
                    if router.phase != .auth {
                        try? await environment.notificationService.registerCurrentDevice()
                    }
                }
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        Group {
            switch router.phase {
            case .loading:
                LaunchView()
            case .auth:
                AuthView()
            case .profileSetup:
                ProfileSetupView()
            case .squadSetup:
                SquadSetupView()
            case .widgetIntro:
                WidgetIntroView()
            case .main:
                MainShellView()
            }
        }
    }
}

private struct LaunchView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Loading PlaySnap")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
}

private struct MainShellView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "rectangle.stack.fill")
                }
                .tag(MainTab.feed)

            TournamentView()
                .tabItem {
                    Label("Game", systemImage: "sportscourt.fill")
                }
                .tag(MainTab.game)

            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(MainTab.camera)

            NotificationsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .tag(MainTab.notifications)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(MainTab.profile)
        }
    }
}
