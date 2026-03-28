import SwiftUI

struct SquadSetupView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = SquadSetupViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Picker("Action", selection: $viewModel.mode) {
                        ForEach(SquadSetupMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(viewModel.mode.sectionTitle) {
                    TextField(viewModel.mode.placeholder, text: $viewModel.input)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                }

                Section {
                    Button(viewModel.mode.buttonTitle) {
                        Task {
                            await viewModel.submit(
                                squadService: environment.squadService,
                                authService: environment.authService,
                                router: router
                            )
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSaving)
                }

                if let createdSquad = viewModel.lastResolvedSquad {
                    Section("Preview") {
                        LabeledContent("Squad", value: createdSquad.name)
                        LabeledContent("Invite code", value: createdSquad.inviteCode)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Your squad")
        }
    }
}
