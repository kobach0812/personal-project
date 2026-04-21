import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Loading alerts...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "Could not load alerts",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No alerts yet",
                        systemImage: "bell.slash",
                        description: Text("You'll see reactions and new plays here.")
                    )
                } else {
                    List(viewModel.notifications) { notification in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(notification.title)
                                    .font(.headline)
                                Spacer()
                                if notification.readAt == nil {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                }
                            }

                            Text(notification.message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .refreshable {
                        await viewModel.load(notificationService: environment.notificationService)
                    }
                }
            }
            .navigationTitle("Alerts")
            .task {
                await viewModel.load(notificationService: environment.notificationService)
            }
        }
    }
}
