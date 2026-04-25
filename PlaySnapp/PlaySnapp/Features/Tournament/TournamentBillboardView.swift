import SwiftUI

struct TournamentBillboardView: View {
    let players: [TournamentPlayer]

    private var sorted: [TournamentPlayer] {
        players.sorted {
            if $0.wins != $1.wins     { return $0.wins > $1.wins }
            if $0.losses != $1.losses { return $0.losses < $1.losses }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                Divider()
                if sorted.isEmpty {
                    ContentUnavailableView(
                        "No results yet",
                        systemImage: "list.number",
                        description: Text("Record match results to see standings.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { rank, player in
                        playerRow(rank: rank + 1, player: player)
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.top)
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Player").frame(maxWidth: .infinity, alignment: .leading)
            Text("Played").frame(width: 52, alignment: .center)
            Text("W").frame(width: 32, alignment: .center)
            Text("L").frame(width: 32, alignment: .center)
            Text("Pts").frame(width: 40, alignment: .center)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func playerRow(rank: Int, player: TournamentPlayer) -> some View {
        HStack {
            Text("\(rank). \(player.name)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(rank == 1 ? .semibold : .regular)
            Text("\(player.played)").frame(width: 52, alignment: .center)
            Text("\(player.wins)").frame(width: 32, alignment: .center)
            Text("\(player.losses)").frame(width: 32, alignment: .center)
            Text("\(player.wins)").frame(width: 40, alignment: .center).fontWeight(.semibold)
        }
        .font(.callout)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
