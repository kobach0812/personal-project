import SwiftUI

/// Horizontal single-elimination bracket — rounds laid out as columns left→right
/// (Quarterfinals → Semifinals → Final → Champion), match nodes joined by elbow
/// connector lines that converge on the champion. Horizontally scrollable; the
/// vertical pitch doubles each round so every node sits centered on the two it
/// feeds from. Styled with the Athletic Pro design tokens.
struct BracketKnockoutView: View {
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterSet: (KnockoutMatch) -> Void

    /// Left→right column order, widest round first.
    private static let columnOrder: [KnockoutRound] = [.quarterfinal, .semifinal, .final]

    /// Every round from the first *generated* round through the Final — including rounds
    /// not yet created by the engine. Those render as "Winner of …" placeholders, so the
    /// full bracket shape is visible from the opening match.
    private var rounds: [KnockoutRound] {
        guard let start = Self.columnOrder.firstIndex(where: { !vm.knockoutMatches(in: $0).isEmpty })
        else { return [] }
        return Array(Self.columnOrder[start...])
    }

    /// Matches in the first generated round drive the whole tree's width: round `k`
    /// holds `startingMatchCount / 2^k` slots.
    private var startingMatchCount: Int {
        guard let first = rounds.first else { return 0 }
        return vm.knockoutMatches(in: first).count
    }

    private func slotCount(column: Int) -> Int {
        max(1, startingMatchCount / (1 << column))
    }

    private var thirdPlace: KnockoutMatch? {
        vm.knockoutMatches(in: .thirdPlace).first
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: ThemeSpacing.xl) {
                if let champion = vm.champion {
                    ChampionBanner(teamName: champion.name)
                } else {
                    KnockoutHeaderTile(bestOf: vm.knockoutBestOf)
                }

                bracket

                if let third = thirdPlace {
                    ThirdPlaceCard(match: third, vm: vm, onEnterSet: onEnterSet)
                }

                if vm.isOrganizer && vm.champion == nil {
                    Label("Tap a live match to enter a set", systemImage: "hand.tap.fill")
                        .font(ThemeFont.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
            .padding(.horizontal, ThemeSpacing.lg)
            .padding(.vertical, ThemeSpacing.xl)
        }
        .background(ThemeColor.surface)
    }

    // MARK: - Horizontal bracket tree

    private var bracket: some View {
        let columns = rounds.enumerated().map { index, round in
            BracketColumn(round: round,
                          matches: vm.knockoutMatches(in: round),
                          slots: slotCount(column: index))
        }
        let slotCounts = columns.map(\.slots)
        let layout = TreeLayout(
            roundCount: columns.count,
            round0Count: columns.first?.slots ?? 1,
            hasChampion: vm.champion != nil
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                BracketConnectors(layout: layout, slotCounts: slotCounts)
                    .stroke(ThemeColor.textSecondary.opacity(0.45), lineWidth: 1.5)

                // Round labels
                ForEach(Array(columns.enumerated()), id: \.offset) { col, column in
                    RoundLabel(text: column.round.displayName)
                        .position(x: layout.columnX(col), y: 12)
                }
                if vm.champion != nil {
                    RoundLabel(text: "Champion")
                        .position(x: layout.columnX(layout.championColumn), y: 12)
                }

                // Match nodes — real matches, or "Winner of …" placeholders for rounds
                // the engine hasn't generated yet.
                ForEach(Array(columns.enumerated()), id: \.offset) { col, column in
                    ForEach(0..<column.slots, id: \.self) { row in
                        node(column: column, columnIndex: col, row: row, columns: columns)
                            .frame(width: layout.cardW, height: layout.cardH)
                            .position(x: layout.columnX(col),
                                      y: layout.centerY(round: col, index: row))
                    }
                }

                // Champion node
                if let champion = vm.champion {
                    ChampionNode(teamName: champion.name)
                        .frame(width: layout.cardW, height: layout.cardH)
                        .position(x: layout.columnX(layout.championColumn),
                                  y: layout.centerY(round: max(0, columns.count - 1), index: 0))
                }
            }
            .frame(width: layout.totalWidth, height: layout.totalHeight)
            .padding(.trailing, ThemeSpacing.lg)
        }
        .frame(height: layout.totalHeight)
    }

    @ViewBuilder
    private func node(column: BracketColumn, columnIndex: Int, row: Int, columns: [BracketColumn]) -> some View {
        if let match = column.matches.first(where: { $0.position == row }) {
            KnockoutNodeCard(match: match, vm: vm, onEnterSet: onEnterSet)
        } else {
            let feeder = columnIndex > 0 ? columns[columnIndex - 1].round.shortName : "match"
            PlaceholderNode(
                top: "Winner of \(feeder) \(row * 2 + 1)",
                bottom: "Winner of \(feeder) \(row * 2 + 2)"
            )
        }
    }
}

/// One round's worth of the tree: the round, its real matches (may be empty for a
/// not-yet-generated round), and how many slots it should display.
private struct BracketColumn {
    let round: KnockoutRound
    let matches: [KnockoutMatch]
    let slots: Int
}

// MARK: - Tree geometry

/// Pure layout math for the bracket. A node in round `k` is fed by nodes `2j` and
/// `2j+1` of round `k-1`, so the vertical pitch doubles each column and each node is
/// centered on the midpoint of its two feeders.
private struct TreeLayout {
    let roundCount: Int
    let round0Count: Int
    let hasChampion: Bool

    let cardW: CGFloat = 172
    let cardH: CGFloat = 74
    let vGap: CGFloat = 18
    let hGap: CGFloat = 40
    let topInset: CGFloat = 28

    private var pitch: CGFloat { cardH + vGap }

    var championColumn: Int { roundCount }

    func columnX(_ column: Int) -> CGFloat {
        cardW / 2 + CGFloat(column) * (cardW + hGap)
    }

    func centerY(round column: Int, index row: Int) -> CGFloat {
        let span = CGFloat(1 << column)            // 1, 2, 4 … nodes-per-slot
        let step = pitch * span
        let offset = pitch * (span - 1) / 2
        return topInset + offset + step * CGFloat(row) + cardH / 2
    }

    var totalWidth: CGFloat {
        let lastColumn = hasChampion ? roundCount : max(0, roundCount - 1)
        return cardW + CGFloat(lastColumn) * (cardW + hGap)
    }

    var totalHeight: CGFloat {
        topInset + pitch * CGFloat(max(1, round0Count)) + topInset / 2
    }
}

// MARK: - Connector lines

/// Elbow connectors joining each node to the two nodes that feed it, plus the
/// straight run from the final into the champion node.
private struct BracketConnectors: Shape {
    let layout: TreeLayout
    /// Number of nodes shown in each round column, including placeholder rounds.
    let slotCounts: [Int]

    func path(in _: CGRect) -> Path {
        var path = Path()
        guard slotCounts.count > 1 else {
            return championPath(into: path)
        }

        for column in 1..<slotCounts.count {
            for row in 0..<slotCounts[column] {
                let nodeLeft = layout.columnX(column) - layout.cardW / 2
                let nodeY = layout.centerY(round: column, index: row)
                let feederRight = layout.columnX(column - 1) + layout.cardW / 2
                let midX = (feederRight + nodeLeft) / 2

                for feeder in [row * 2, row * 2 + 1] where feeder < slotCounts[column - 1] {
                    let feederY = layout.centerY(round: column - 1, index: feeder)
                    path.move(to: CGPoint(x: feederRight, y: feederY))
                    path.addLine(to: CGPoint(x: midX, y: feederY))
                    path.addLine(to: CGPoint(x: midX, y: nodeY))
                    path.addLine(to: CGPoint(x: nodeLeft, y: nodeY))
                }
            }
        }

        return championPath(into: path)
    }

    /// Straight run from the final into the champion node.
    private func championPath(into base: Path) -> Path {
        var path = base
        if layout.hasChampion, !slotCounts.isEmpty {
            let finalCol = slotCounts.count - 1
            let y = layout.centerY(round: finalCol, index: 0)
            let fromX = layout.columnX(finalCol) + layout.cardW / 2
            let toX = layout.columnX(layout.championColumn) - layout.cardW / 2
            path.move(to: CGPoint(x: fromX, y: y))
            path.addLine(to: CGPoint(x: toX, y: y))
        }

        return path
    }
}

// MARK: - Round label

private struct RoundLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(ThemeFont.meta.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(ThemeColor.textSecondary)
    }
}

// MARK: - Match node

/// A single bracket node: two stacked team rows showing seed, name, and sets won.
/// Live organizer-tappable matches get a primary border + a LIVE pill.
private struct KnockoutNodeCard: View {
    let match: KnockoutMatch
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterSet: (KnockoutMatch) -> Void

    private var isBye: Bool { match.teamBID == nil }
    private var isLive: Bool { match.winnerTeamID == nil && !isBye }
    private var canEnter: Bool { isLive && vm.isOrganizer }

    var body: some View {
        Group {
            if canEnter {
                Button { onEnterSet(match) } label: { card }
                    .buttonStyle(.plain)
            } else {
                card
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            NodeTeamRow(
                teamID: match.teamAID,
                setsWon: setsWon(forTeamA: true),
                isWinner: match.winnerTeamID == match.teamAID && match.teamAID != nil,
                vm: vm
            )
            Divider().background(ThemeColor.textSecondary.opacity(0.15))
            if isBye {
                ByeRow()
            } else {
                NodeTeamRow(
                    teamID: match.teamBID,
                    setsWon: setsWon(forTeamA: false),
                    isWinner: match.winnerTeamID == match.teamBID && match.teamBID != nil,
                    vm: vm
                )
            }
        }
        .cardSurface()
        .overlay(alignment: .leading) {
            // Live matches get an energy accent rail on the leading edge — the two
            // rows already occupy every corner, so a rail avoids colliding with
            // seed badges or set counts while keeping the card height fixed.
            if isLive {
                Capsule()
                    .fill(ThemeColor.energy)
                    .frame(width: 4)
                    .padding(.vertical, ThemeSpacing.sm)
            }
        }
        .overlay {
            if canEnter {
                RoundedRectangle(cornerRadius: ThemeRadius.xl)
                    .strokeBorder(ThemeColor.primary.opacity(0.45), lineWidth: 1.5)
            }
        }
    }

    private func setsWon(forTeamA: Bool) -> Int {
        match.sets.filter { forTeamA ? $0.teamAScore > $0.teamBScore : $0.teamBScore > $0.teamAScore }.count
    }
}

private struct NodeTeamRow: View {
    let teamID: String?
    let setsWon: Int
    let isWinner: Bool
    @ObservedObject var vm: BracketDetailViewModel

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            if let teamID, let seed = vm.seedLabel(for: teamID) {
                Badge(seed, style: isWinner ? .accent : .neutral)
            }
            Text(teamID == nil ? "TBD" : vm.teamName(teamID))
                .font(ThemeFont.body.weight(isWinner ? .semibold : .regular))
                .foregroundStyle(rowColor)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: ThemeSpacing.xs)
            if isWinner {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ThemeColor.accent)
            }
            ScoreText("\(setsWon)", emphasized: isWinner)
                .frame(minWidth: 16, alignment: .trailing)
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.vertical, ThemeSpacing.sm + 1)
    }

    private var rowColor: Color {
        if teamID == nil { return ThemeColor.textSecondary }
        return isWinner ? ThemeColor.textPrimary : ThemeColor.textSecondary
    }
}

private struct ByeRow: View {
    var body: some View {
        HStack {
            Text("BYE")
                .font(ThemeFont.caption.weight(.medium))
                .foregroundStyle(ThemeColor.textSecondary)
            Spacer()
            Image(systemName: "arrow.right.circle")
                .font(.system(size: 11))
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.vertical, ThemeSpacing.sm + 1)
    }
}

// MARK: - Placeholder node

/// A future match whose teams aren't decided yet — shows where each entrant will
/// come from (e.g. "Winner of Semifinal 1"). Dashed border marks it as pending.
private struct PlaceholderNode: View {
    let top: String
    let bottom: String

    var body: some View {
        VStack(spacing: 0) {
            row(top)
            Divider().background(ThemeColor.textSecondary.opacity(0.12))
            row(bottom)
        }
        .background(ThemeColor.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xl)
                .strokeBorder(
                    ThemeColor.textSecondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        )
    }

    private func row(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(ThemeFont.caption)
                .foregroundStyle(ThemeColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.vertical, ThemeSpacing.sm + 1)
    }
}

// MARK: - Champion node

/// Compact trophy node that caps the tree to the right of the final.
private struct ChampionNode: View {
    let teamName: String

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 18))
                .foregroundStyle(ThemeColor.champion)
            Text(teamName)
                .font(ThemeFont.body.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, ThemeSpacing.sm)
        .background(
            LinearGradient(
                colors: [ThemeColor.champion.opacity(0.18), ThemeColor.energy.opacity(0.06)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xl)
                .strokeBorder(ThemeColor.champion.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Header tile

private struct KnockoutHeaderTile: View {
    let bestOf: Int

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                Text("KNOCKOUT")
                    .font(ThemeFont.meta.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(ThemeColor.textSecondary)
                Text("Single elimination")
                    .font(ThemeFont.title)
                    .foregroundStyle(ThemeColor.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Best of")
                    .font(ThemeFont.meta)
                    .foregroundStyle(ThemeColor.textSecondary)
                Text("\(bestOf)")
                    .font(ThemeFont.display)
                    .foregroundStyle(ThemeColor.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ThemeSpacing.lg)
        .cardSurface()
    }
}

// MARK: - Third place

private struct ThirdPlaceCard: View {
    let match: KnockoutMatch
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterSet: (KnockoutMatch) -> Void

    private var isLive: Bool { match.winnerTeamID == nil && match.teamBID != nil }
    private var canEnter: Bool { isLive && vm.isOrganizer }

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            RoundLabel(text: "3rd Place Match")
            Group {
                if canEnter {
                    Button { onEnterSet(match) } label: { node }
                        .buttonStyle(.plain)
                } else {
                    node
                }
            }
        }
    }

    private var node: some View {
        KnockoutNodeCard(match: match, vm: vm, onEnterSet: onEnterSet)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Champion banner

private struct ChampionBanner: View {
    let teamName: String

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(ThemeColor.champion)

            Text("CHAMPION")
                .font(ThemeFont.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(ThemeColor.textSecondary)

            Text(teamName)
                .font(ThemeFont.display)
                .foregroundStyle(ThemeColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ThemeSpacing.xl)
        .background(
            LinearGradient(
                colors: [ThemeColor.champion.opacity(0.18), ThemeColor.energy.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl + 4))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xl + 4)
                .strokeBorder(ThemeColor.champion.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Round display names

private extension KnockoutRound {
    var displayName: String {
        switch self {
        case .quarterfinal: return "Quarterfinals"
        case .semifinal:    return "Semifinals"
        case .final:        return "Final"
        case .thirdPlace:   return "3rd Place"
        }
    }

    /// Singular form used in placeholder labels, e.g. "Winner of Semifinal 1".
    var shortName: String {
        switch self {
        case .quarterfinal: return "Quarterfinal"
        case .semifinal:    return "Semifinal"
        case .final:        return "Final"
        case .thirdPlace:   return "3rd Place"
        }
    }
}

// MARK: - Previews

#if DEBUG
/// Deterministic stub data so the bracket geometry can be eyeballed without running
/// the full create → group → configure flow. Temporary preview scaffolding (also
/// drives the snapshot test that renders the tree to a PNG).
enum BracketPreviewData {
    static let groups: [BracketGroup] = [
        group("A", ["a1": "Falcons", "a2": "Hawks", "a3": "Owls", "a4": "Wrens"]),
        group("B", ["b1": "Bears", "b2": "Foxes", "b3": "Lynx", "b4": "Wolves"])
    ]

    static func group(_ name: String, _ teams: [String: String]) -> BracketGroup {
        BracketGroup(
            id: "g\(name)",
            name: name,
            teams: teams.sorted { $0.value < $1.value }
                .map { FixedTeam(id: $0.key, name: $0.value, playerIDs: ["p1", "p2"]) },
            matches: [],
            advanceCount: 4
        )
    }

    static func km(
        _ round: KnockoutRound, _ position: Int,
        _ teamA: String?, _ teamB: String?,
        winner: String? = nil, sets: [(Int, Int)] = []
    ) -> KnockoutMatch {
        KnockoutMatch(
            id: "\(round.rawValue)-\(position)",
            round: round, position: position,
            teamAID: teamA, teamBID: teamB,
            sets: sets.map { SetScore(teamAScore: $0.0, teamBScore: $0.1) },
            winnerTeamID: winner,
            completedAt: winner != nil ? .now : nil
        )
    }

    @MainActor
    static func viewModel(status: BracketStatus, matches: [KnockoutMatch]) -> BracketDetailViewModel {
        let bracket = BracketTournament(
            id: "b1", parentTournamentID: "t1", squadID: "s1",
            createdBy: "org", createdAt: .now, title: "Summer Cup",
            status: status, groups: groups, knockoutBestOf: 3, knockoutMatches: matches
        )
        let organizer = AppUser(
            id: "org", name: "Organizer", avatarURL: nil,
            activeSquadID: "s1", createdAt: .now, updatedAt: .now
        )
        let vm = BracketDetailViewModel()
        vm.start(bracket: bracket, currentUser: organizer, service: StubBracketTournamentService())
        return vm
    }

    @MainActor static var finished: BracketDetailViewModel {
        viewModel(status: .finished, matches: [
            km(.quarterfinal, 0, "a1", "b4", winner: "a1", sets: [(21, 15), (21, 18)]),
            km(.quarterfinal, 1, "b1", "a4", winner: "b1", sets: [(21, 12), (21, 19)]),
            km(.quarterfinal, 2, "a2", "b3", winner: "a2", sets: [(21, 17), (18, 21), (21, 16)]),
            km(.quarterfinal, 3, "b2", "a3", winner: "b2", sets: [(21, 14), (21, 13)]),
            km(.semifinal, 0, "a1", "b1", winner: "a1", sets: [(21, 18), (21, 19)]),
            km(.semifinal, 1, "a2", "b2", winner: "a2", sets: [(19, 21), (21, 17), (21, 15)]),
            km(.final, 0, "a1", "a2", winner: "a1", sets: [(21, 16), (21, 18)]),
            km(.thirdPlace, 0, "b1", "b2", winner: "b1", sets: [(21, 19), (21, 17)])
        ])
    }

    @MainActor static var live: BracketDetailViewModel {
        viewModel(status: .knockout, matches: [
            km(.quarterfinal, 0, "a1", "b2", winner: "a1", sets: [(21, 18), (21, 16)]),
            km(.quarterfinal, 1, "a2", "b1", sets: [(21, 18)]),   // live, 1–0
            km(.quarterfinal, 2, "a3", nil, winner: "a3")          // bye
        ])
    }

    /// 4-team bracket at the opening: semifinals exist, the final isn't generated yet
    /// so it shows as a "Winner of Semifinal …" placeholder.
    @MainActor static var start: BracketDetailViewModel {
        viewModel(status: .knockout, matches: [
            km(.semifinal, 0, "b1", "a1", winner: "b1", sets: [(21, 15), (21, 18)]),
            km(.semifinal, 1, "a2", nil, winner: "a2")             // bye
        ])
    }
}

#Preview("Knockout · Finished (8 teams)") {
    BracketKnockoutView(vm: BracketPreviewData.finished) { _ in }
}

#Preview("Knockout · Live (5 teams + bye)") {
    BracketKnockoutView(vm: BracketPreviewData.live) { _ in }
}

#Preview("Knockout · Start (final placeholder)") {
    BracketKnockoutView(vm: BracketPreviewData.start) { _ in }
}
#endif
