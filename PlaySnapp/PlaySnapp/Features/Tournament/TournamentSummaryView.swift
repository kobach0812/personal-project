import SwiftUI

struct TournamentSummaryView: View {
    let session: TournamentSession

    private var duration: String? {
        guard let ended = session.endedAt else { return nil }
        let total = Int(ended.timeIntervalSince(session.createdAt))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeCard
                playersCard
            }
            .padding()
        }
    }

    // MARK: - Time card

    private var timeCard: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "clock",
                label: "Started",
                value: session.createdAt.formatted(date: .omitted, time: .shortened)
            )
            if let ended = session.endedAt {
                Divider().padding(.leading, 44)
                infoRow(
                    icon: "clock.badge.checkmark",
                    label: "Ended",
                    value: ended.formatted(date: .omitted, time: .shortened)
                )
            }
            if let dur = duration {
                Divider().padding(.leading, 44)
                infoRow(icon: "timer", label: "Duration", value: dur)
            }
            Divider().padding(.leading, 44)
            infoRow(
                icon: "sportscourt",
                label: "Courts",
                value: "\(session.courts)"
            )
            Divider().padding(.leading, 44)
            infoRow(
                icon: "checkmark.circle",
                label: "Matches played",
                value: "\(session.completedMatches.count)"
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Players card

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Players involved (\(session.players.count))")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ForEach(session.players.sorted { $0.wins > $1.wins }) { player in
                Divider().padding(.leading, 16)
                HStack {
                    Text(player.name)
                    Spacer()
                    HStack(spacing: 12) {
                        statBadge(value: player.played, label: "P", color: .secondary)
                        statBadge(value: player.wins,   label: "W", color: .green)
                        statBadge(value: player.losses, label: "L", color: .red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func statBadge(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.callout.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 28)
    }
}
