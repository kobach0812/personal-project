import SwiftUI

struct PlayDetailView: View {
    let play: Play

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.65), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 340)

                Text(play.senderName)
                    .font(.title2.bold())

                if let caption = play.caption {
                    Text(caption)
                        .font(.body)
                }

                HStack(spacing: 10) {
                    ForEach(play.reactionSummary.keys.sorted(), id: \.self) { key in
                        Text("\(key) \(play.reactionSummary[key, default: 0])")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }

                Text("Posted \(play.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}
