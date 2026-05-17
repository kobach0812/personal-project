import SwiftUI

struct BracketRow: View {
    let bracket: BracketTournament

    private var statusLabel: String {
        switch bracket.status {
        case .setup:                return "Setup"
        case .groupStage:           return "Group Stage"
        case .configuringKnockout:  return "Configuring Knockout"
        case .knockout:             return "Knockout"
        case .finished:             return "Finished"
        }
    }

    private var statusColor: Color {
        switch bracket.status {
        case .setup, .configuringKnockout: return .orange
        case .groupStage:                  return .green
        case .knockout:                    return .blue
        case .finished:                    return .secondary
        }
    }

    private var teamCount: Int {
        bracket.groups.reduce(0) { $0 + $1.teams.count }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(bracket.title.isEmpty ? "Bracket" : bracket.title)
                    .font(.body)
                Text("\(teamCount) team\(teamCount == 1 ? "" : "s") · \(bracket.groups.count) group\(bracket.groups.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(statusLabel)
                .font(.caption.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 2)
    }
}
