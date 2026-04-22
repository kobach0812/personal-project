import SwiftUI

struct TournamentHistoryView: View {
    @ObservedObject var vm: TournamentViewModel

    var body: some View {
        Group {
            if let session = vm.session, !session.completedMatches.isEmpty {
                List(session.completedMatches) { match in
                    HistoryRow(match: match, vm: vm)
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(
                    "No matches yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed matches will appear here.")
                )
            }
        }
    }
}

private struct HistoryRow: View {
    let match: TournamentMatch
    @ObservedObject var vm: TournamentViewModel

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
                teamLabel(ids: match.teamA, isWinner: match.winnerTeam == .teamA)
                scoreLabel(score: match.teamAScore)
                Text("–").foregroundStyle(.secondary)
                scoreLabel(score: match.teamBScore)
                teamLabel(ids: match.teamB, isWinner: match.winnerTeam == .teamB)
            }
            .font(.callout)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func teamLabel(ids: [String], isWinner: Bool) -> some View {
        Text(ids.map { vm.playerName($0) }.joined(separator: " & "))
            .fontWeight(isWinner ? .semibold : .regular)
            .frame(maxWidth: .infinity, alignment: ids == match.teamA ? .leading : .trailing)
    }

    @ViewBuilder
    private func scoreLabel(score: Int?) -> some View {
        if let score {
            Text("\(score)")
                .fontWeight(.semibold)
                .monospacedDigit()
        } else {
            Text("–")
                .foregroundStyle(.secondary)
        }
    }
}
