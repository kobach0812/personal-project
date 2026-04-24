import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                // MARK: Player info
                Section("Player") {
                    LabeledContent("Name", value: viewModel.user?.name ?? "—")
                }

                if viewModel.isLoading {
                    Section {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                }

                // MARK: Squads
                Section {
                    ForEach(viewModel.allSquads) { squad in
                        Button {
                            Task {
                                await viewModel.switchSquad(
                                    to: squad,
                                    squadService: environment.squadService
                                )
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(squad.name)
                                        .foregroundStyle(.primary)
                                    Text("Code: \(squad.inviteCode)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if squad.id == viewModel.user?.activeSquadID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }

                    Button {
                        viewModel.addSquadInput = ""
                        viewModel.addSquadError = nil
                        viewModel.addSquadMode = .create
                        viewModel.isAddingSquad = true
                    } label: {
                        Label("Add a squad", systemImage: "plus.circle")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Squads (\(viewModel.allSquads.count))")
                }

                // MARK: Friends
                Section {
                    NavigationLink {
                        FriendsView()
                            .environmentObject(environment)
                    } label: {
                        Label("Friends", systemImage: "person.2")
                    }
                }

                // MARK: Account
                Section {
                    Button("Sign out", role: .destructive) {
                        Task {
                            await viewModel.signOut(
                                authService: environment.authService,
                                router: router
                            )
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { viewModel.startEditing() }
                }
            }
            .sheet(isPresented: $viewModel.isEditingProfile) {
                ProfileEditSheet(viewModel: viewModel)
                    .environmentObject(environment)
            }
            .sheet(isPresented: $viewModel.isAddingSquad) {
                AddSquadSheet(viewModel: viewModel)
                    .environmentObject(environment)
            }
            .task {
                await viewModel.load(
                    profileService: environment.userProfileService,
                    squadService: environment.squadService
                )
            }
        }
    }
}

// MARK: - Profile Edit Sheet

private struct ProfileEditSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        NavigationStack {
            Form {
                Section("Display name") {
                    TextField("Name", text: $viewModel.editName)
                        .autocorrectionDisabled()
                }

                if let error = viewModel.saveError {
                    Section {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isEditingProfile = false }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await viewModel.saveProfile(
                                    profileService: environment.userProfileService
                                )
                            }
                        }
                        .disabled(viewModel.editName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Add Squad Sheet

private struct AddSquadSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var environment: AppEnvironment

    var canSubmit: Bool {
        !viewModel.addSquadInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Picker("Action", selection: $viewModel.addSquadMode) {
                        ForEach(SquadSetupMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(viewModel.addSquadMode.sectionTitle) {
                    TextField(viewModel.addSquadMode.placeholder, text: $viewModel.addSquadInput)
                        .textInputAutocapitalization(
                            viewModel.addSquadMode == .join ? .characters : .words
                        )
                        .autocorrectionDisabled()
                }

                if let error = viewModel.addSquadError {
                    Section {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.addSquadMode == .create ? "New Squad" : "Join Squad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isAddingSquad = false }
                        .disabled(viewModel.isAddingSquadSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isAddingSquadSaving {
                        ProgressView()
                    } else {
                        Button(viewModel.addSquadMode.buttonTitle) {
                            Task {
                                await viewModel.addSquad(squadService: environment.squadService)
                            }
                        }
                        .disabled(!canSubmit)
                    }
                }
            }
        }
    }
}
