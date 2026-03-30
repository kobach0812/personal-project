import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("PlaySnap")
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                Text("Share real plays with your squad instantly.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await viewModel.continueWithApple(
                        authService: environment.authService,
                        router: router
                    )
                }
            } label: {
                HStack {
                    Image(systemName: "apple.logo")
                    Text(viewModel.isLoading ? "Signing in..." : "Continue with Apple")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Text("Continue with Apple now uses Firebase Auth. If it fails, check Firebase Apple provider setup and Xcode signing.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
    }
}
