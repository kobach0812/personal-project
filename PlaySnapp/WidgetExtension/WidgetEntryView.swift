import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer()
            Text(entry.payload?.senderName ?? "No plays yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text(entry.payload?.sportName ?? "PlaySnapp")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .containerBackground(for: .widget) {
            ZStack {
                if let thumbnail = localThumbnail() {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    gradientBackground
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
    }

    private func localThumbnail() -> UIImage? {
        guard let data = AppGroupStore.loadThumbnailData() else { return nil }
        return UIImage(data: data)
    }

    private var gradientBackground: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.85), Color.red.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
