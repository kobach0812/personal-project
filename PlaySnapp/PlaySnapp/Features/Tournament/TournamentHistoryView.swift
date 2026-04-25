import SwiftUI

struct TournamentHistoryView: View {
    let matches: [TournamentMatch]
    let playerName: (String) -> String

    var body: some View {
        Group {
            if matches.isEmpty {
                ContentUnavailableView(
                    "No matches yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed matches will appear here.")
                )
            } else {
                List(matches) { match in
                    HistoryRow(match: match, playerName: playerName)
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct HistoryRow: View {
    let match: TournamentMatch
    let playerName: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Court \(match.court)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let date = match.completedAt {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 6) {
                teamLabel(ids: match.teamA, isWinner: match.winnerTeam == .teamA, alignment: .leading)
                scoreLabel(score: match.teamAScore)
                Text("–").foregroundStyle(.secondary)
                scoreLabel(score: match.teamBScore)
                teamLabel(ids: match.teamB, isWinner: match.winnerTeam == .teamB, alignment: .trailing)
            }
            .font(.callout)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func teamLabel(ids: [String], isWinner: Bool, alignment: Alignment) -> some View {
        Text(ids.map { playerName($0) }.joined(separator: " & "))
            .fontWeight(isWinner ? .semibold : .regular)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    @ViewBuilder
    private func scoreLabel(score: Int?) -> some View {
        if let score {
            Text("\(score)").fontWeight(.semibold).monospacedDigit()
        } else {
            Text("–").foregroundStyle(.secondary)
        }
    }
}
