import SwiftUI

/// Group-stage screen, bento composition: a top grid of stat tiles (progress · leader)
/// as the focal point, then a card per group with standings + that group's matches, and
/// a primary "Configure Knockout" CTA once the stage is complete. Athletic Pro tokens.
struct BracketGroupStageView: View {
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterScore: (BracketGroup, GroupMatch) -> Void
    let onConfigureKnockout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.xl) {
                bentoHeader

                ForEach(vm.bracket?.groups ?? []) { group in
                    GroupCard(group: group, vm: vm, onEnterScore: onEnterScore)
                }

                if vm.groupStageComplete, vm.isOrganizer {
                    Button("Configure Knockout", action: onConfigureKnockout)
                        .buttonStyle(.primary)
                }
            }
            .padding(.horizontal, ThemeSpacing.lg)
            .padding(.vertical, ThemeSpacing.xl)
        }
        .background(ThemeColor.surface)
    }

    // MARK: - Bento header

    private var bentoHeader: some View {
        HStack(alignment: .top, spacing: ThemeSpacing.md) {
            ProgressTile(played: vm.groupMatchesPlayed, total: vm.groupMatchesTotal)
            LeaderTile(leader: vm.overallLeader)
        }
    }
}

// MARK: - Bento tiles

private struct BentoTile<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(ThemeSpacing.lg)
            .cardSurface()
    }
}

private struct TileLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(ThemeFont.meta.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(ThemeColor.textSecondary)
    }
}

private struct ProgressTile: View {
    let played: Int
    let total: Int

    private var fraction: Double { total == 0 ? 0 : Double(played) / Double(total) }

    var body: some View {
        BentoTile {
            VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                TileLabel(text: "GROUP STAGE")
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(played)")
                        .font(ThemeFont.display)
                        .foregroundStyle(ThemeColor.textPrimary)
                    Text("/ \(total)")
                        .font(ThemeFont.title)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
                Text("matches played")
                    .font(ThemeFont.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
                Spacer(minLength: 0)
                ProgressBar(fraction: fraction)
            }
        }
    }
}

private struct LeaderTile: View {
    let leader: BracketDetailViewModel.TeamRecord?

    var body: some View {
        BentoTile {
            VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                TileLabel(text: "LEADER")
                if let leader {
                    HStack(spacing: ThemeSpacing.sm - 2) {
                        Circle()
                            .fill(ThemeColor.accent)
                            .frame(width: 8, height: 8)
                        Text(leader.team.name)
                            .font(ThemeFont.title)
                            .foregroundStyle(ThemeColor.textPrimary)
                            .lineLimit(1)
                    }
                    Text("\(leader.wins)–\(leader.losses) · \(signed(leader.diff)) diff")
                        .font(ThemeFont.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                } else {
                    Text("—")
                        .font(ThemeFont.display)
                        .foregroundStyle(ThemeColor.textSecondary)
                    Text("no matches yet")
                        .font(ThemeFont.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func signed(_ n: Int) -> String { n >= 0 ? "+\(n)" : "\(n)" }
}

private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(ThemeColor.textSecondary.opacity(0.15))
                Capsule()
                    .fill(ThemeColor.accent)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Group card

private struct GroupCard: View {
    let group: BracketGroup
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterScore: (BracketGroup, GroupMatch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.md) {
            Text("GROUP \(group.name.uppercased())")
                .font(ThemeFont.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(ThemeColor.textSecondary)

            VStack(spacing: 0) {
                let standings = Array(vm.groupStandings(for: group).enumerated())
                ForEach(standings, id: \.element.id) { idx, team in
                    StandingRow(rank: idx + 1, team: team, group: group, vm: vm)
                    if idx < standings.count - 1 {
                        Divider().background(ThemeColor.textSecondary.opacity(0.12))
                    }
                }

                if !group.matches.isEmpty {
                    Divider().background(ThemeColor.textSecondary.opacity(0.2))
                        .padding(.vertical, ThemeSpacing.xs)
                    ForEach(group.matches) { match in
                        MatchRow(
                            match: match,
                            teamAName: vm.teamName(match.teamAID, in: group),
                            teamBName: vm.teamName(match.teamBID, in: group),
                            isOrganizer: vm.isOrganizer,
                            onEnterScore: { onEnterScore(group, match) }
                        )
                    }
                }
            }
            .padding(ThemeSpacing.md)
            .cardSurface()
        }
    }
}

private struct StandingRow: View {
    let rank: Int
    let team: FixedTeam
    let group: BracketGroup
    @ObservedObject var vm: BracketDetailViewModel

    private var isLeader: Bool { rank == 1 }

    var body: some View {
        HStack(spacing: ThemeSpacing.md) {
            Badge("\(rank)", style: isLeader ? .accent : .neutral)
            Text(team.name)
                .font(ThemeFont.body.weight(isLeader ? .semibold : .regular))
                .foregroundStyle(ThemeColor.textPrimary)
            Spacer()
            ScoreText("\(vm.wins(team.id, in: group))–\(vm.losses(team.id, in: group))",
                      emphasized: isLeader)
            let diff = vm.pointDiff(team.id, in: group)
            Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                .font(ThemeFont.meta.monospaced())
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.vertical, ThemeSpacing.sm)
    }
}

private struct MatchRow: View {
    let match: GroupMatch
    let teamAName: String
    let teamBName: String
    let isOrganizer: Bool
    let onEnterScore: () -> Void

    var body: some View {
        if let a = match.scoreA, let b = match.scoreB, let winner = match.winnerTeamID {
            HStack {
                Text(teamAName)
                    .font(ThemeFont.body.weight(winner == match.teamAID ? .semibold : .regular))
                    .foregroundStyle(winner == match.teamAID ? ThemeColor.textPrimary : ThemeColor.textSecondary)
                Spacer()
                ScoreText("\(a)–\(b)")
                Spacer()
                Text(teamBName)
                    .font(ThemeFont.body.weight(winner == match.teamBID ? .semibold : .regular))
                    .foregroundStyle(winner == match.teamBID ? ThemeColor.textPrimary : ThemeColor.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, ThemeSpacing.sm)
        } else if isOrganizer {
            Button(action: onEnterScore) {
                HStack {
                    Text("\(teamAName) vs \(teamBName)")
                        .font(ThemeFont.body)
                        .foregroundStyle(ThemeColor.textPrimary)
                    Spacer()
                    Text("Enter")
                        .font(ThemeFont.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ThemeColor.primary)
                }
                .padding(.vertical, ThemeSpacing.sm)
            }
            .buttonStyle(.plain)
        } else {
            HStack {
                Text("\(teamAName) vs \(teamBName)")
                    .font(ThemeFont.body)
                    .foregroundStyle(ThemeColor.textPrimary)
                Spacer()
                Text("Awaiting")
                    .font(ThemeFont.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
            }
            .padding(.vertical, ThemeSpacing.sm)
        }
    }
}
