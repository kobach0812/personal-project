import SwiftUI

struct WidgetEntryView: View {
    let entry: WidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.85), Color.red.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Latest squad play")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))

                Text(entry.payload?.senderName ?? "No updates yet")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(entry.payload?.sportName ?? "PlaySnap")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}
