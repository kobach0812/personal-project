import SwiftUI

struct WidgetIntroView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = WidgetIntroViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("Add the widget early")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("The widget is the product shortcut. It keeps your squad visible without opening the app.")
                .font(.title3)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.85), Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest squad moment")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Maya posted a new play")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(20)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Setup")
                    .font(.headline)
                Text("1. Long press the home screen")
                Text("2. Tap the plus button")
                Text("3. Search for PlaySnap")
                Text("4. Add the latest-play widget")
            }
            .foregroundStyle(.secondary)

            Button("Continue to app") {
                Task {
                    await viewModel.finish(
                        progressService: environment.onboardingProgressService,
                        router: router
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isSaving)

            Spacer()
        }
        .padding(24)
    }
}
