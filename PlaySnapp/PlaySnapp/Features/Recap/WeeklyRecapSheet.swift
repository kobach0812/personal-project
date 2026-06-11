import SwiftUI

/// Sheet wrapping the weekly recap card with loading/empty/error states and a
/// `ShareLink` that exports the rendered PNG (M26).
struct WeeklyRecapSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = WeeklyRecapViewModel()
    @State private var exportImage: UIImage?

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .loading:
                    ProgressView("Building your recap…")
                case .empty:
                    ContentUnavailableView(
                        "No plays this week",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Post one to start your recap.")
                    )
                case .error:
                    ContentUnavailableView {
                        Label("Couldn't build recap", systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                case .ready(let recap):
                    ScrollView {
                        WeeklyRecapView(recap: recap, heroImage: vm.heroImage)
                            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl))
                            .themeShadow(.high)
                            .padding(.vertical, ThemeSpacing.xl)
                            .scaleEffect(0.95)
                    }
                }
            }
            .navigationTitle("Weekly recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let exportImage {
                        ShareLink(
                            item: Image(uiImage: exportImage),
                            preview: SharePreview("Weekly recap", image: Image(uiImage: exportImage))
                        )
                    }
                }
            }
            .task { await load() }
            .onChange(of: vm.heroImage) { render() }
            .onChange(of: vm.state) { render() }
        }
    }

    private func load() async {
        await vm.load(playService: env.playService, squadService: env.squadService)
    }

    private func render() {
        guard case .ready(let recap) = vm.state else {
            exportImage = nil
            return
        }
        exportImage = RecapImageRenderer.render(
            WeeklyRecapView(recap: recap, heroImage: vm.heroImage)
        )
    }
}
