import SwiftUI

/// Sheet wrapping the game day recap card with a `ShareLink` export (M26).
/// The recap is built by the caller — this sheet only presents and shares it.
struct GameDayRecapSheet: View {
    let recap: GameDayRecap

    @Environment(\.dismiss) private var dismiss
    @State private var exportImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                GameDayRecapView(recap: recap)
                    .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl))
                    .themeShadow(.high)
                    .padding(.vertical, ThemeSpacing.xl)
                    .scaleEffect(0.95)
            }
            .navigationTitle(recap.championTeamName == nil ? "Day recap" : "Champion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let exportImage {
                        ShareLink(
                            item: Image(uiImage: exportImage),
                            preview: SharePreview(
                                recap.championTeamName == nil ? "Day recap" : "Champion",
                                image: Image(uiImage: exportImage)
                            )
                        )
                    }
                }
            }
            .task {
                exportImage = RecapImageRenderer.render(GameDayRecapView(recap: recap))
            }
        }
    }
}
