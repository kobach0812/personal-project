import SwiftUI

@main
struct PlaySnapApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var environment = AppEnvironment.bootstrap(dataSource: .development)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(environment)
                .task {
                    await router.bootstrap(using: environment.authService)
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
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(MainTab.camera)

            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "rectangle.stack.fill")
                }
                .tag(MainTab.feed)

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
