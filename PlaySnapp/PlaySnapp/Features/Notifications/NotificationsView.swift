import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.notifications) { notification in
                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.headline)
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Alerts")
            .task {
                await viewModel.load(notificationService: environment.notificationService)
            }
        }
    }
}
