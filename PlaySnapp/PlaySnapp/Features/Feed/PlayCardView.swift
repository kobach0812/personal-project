import SwiftUI

struct PlayCardView: View {
    let play: Play
    let onReact: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.6), Color.red.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 8) {
                        Label(play.mediaType == .photo ? "Photo" : "Video", systemImage: play.mediaType == .photo ? "photo.fill" : "video.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())

                        if let durationSeconds = play.durationSeconds {
                            Text("\(durationSeconds)s")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                    .padding(14)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(play.senderName)
                    .font(.headline)

                if let caption = play.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(play.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 10) {
                ForEach(PlayReaction.availableEmojis, id: \.self) { emoji in
                    Button {
                        onReact(emoji)
                    } label: {
                        Text("\(emoji) \(play.reactionSummary[emoji, default: 0])")
                            .font(.subheadline.weight(play.currentUserReaction == emoji ? .bold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                play.currentUserReaction == emoji
                                ? Color.orange.opacity(0.18)
                                : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28))
    }
}
