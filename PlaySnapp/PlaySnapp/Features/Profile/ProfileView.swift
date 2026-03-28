import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Player") {
                    LabeledContent("Name", value: viewModel.user.name)
                    LabeledContent("Sport", value: viewModel.user.primarySport.displayName)
                    LabeledContent("Squad", value: viewModel.squad?.name ?? "No squad")
                }

                Section("MVP status") {
                    Text("Firebase profile persistence, avatar upload, and sign out wiring are the next profile tasks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Sign out") {
                        Task {
                            await viewModel.signOut(
                                authService: environment.authService,
                                router: router
                            )
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
            .task {
                await viewModel.load(squadService: environment.squadService)
            }
        }
    }
}
