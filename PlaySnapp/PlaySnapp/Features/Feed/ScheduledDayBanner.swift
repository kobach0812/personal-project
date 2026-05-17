import SwiftUI

struct ScheduledDayBanner: View {
    let session: TournamentSession
    var onTap: () -> Void

    private var timeLabel: String {
        guard let start = session.scheduledStart else { return "" }
        return start.formatted(date: .omitted, time: .shortened)
    }

    private var goingCount: Int { 0 } // Populated by the feed VM if needed; kept simple for now

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Game day today\(timeLabel.isEmpty ? "" : " at \(timeLabel)")")
                        .font(.subheadline.bold())
                    if let title = session.title.isEmpty ? nil : session.title {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
