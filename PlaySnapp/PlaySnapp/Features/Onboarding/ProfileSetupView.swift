import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = ProfileSetupViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $viewModel.name)

                    Picker("Primary sport", selection: $viewModel.selectedSport) {
                        ForEach(Sport.allCases) { sport in
                            Text(sport.displayName).tag(sport)
                        }
                    }
                }

                Section {
                    Button("Save and continue") {
                        Task {
                            await viewModel.saveProfile(
                                authService: environment.authService,
                                router: router
                            )
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSaving)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Set profile")
        }
    }
}
