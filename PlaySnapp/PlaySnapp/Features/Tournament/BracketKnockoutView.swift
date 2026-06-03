import SwiftUI

/// Vertical knockout bracket — rounds stacked most-advanced-first, with a gold champion
/// banner once the final is decided. Styled in the "Athletic Pro" lane (the locked design
/// direction): emerald winner scores, gold trophy moment, slate seed pills.
struct BracketKnockoutView: View {
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterSet: (KnockoutMatch) -> Void

    /// Display order — Final at the top as the climax, 3rd-place match last.
    private static let roundOrder: [KnockoutRound] = [.final, .semifinal, .quarterfinal, .thirdPlace]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let champion = vm.champion {
                    ChampionBanner(teamName: champion.name)
                }

                ForEach(Self.roundOrder, id: \.self) { round in
                    let matches = vm.knockoutMatches(in: round)
                    if !matches.isEmpty {
                        RoundSection(
                            title: round.displayName,
                            matches: matches,
                            vm: vm,
                            onEnterSet: onEnterSet
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(BracketTheme.surface)
    }
}

// MARK: - Round section

private struct RoundSection: View {
    let title: String
    let matches: [KnockoutMatch]
    @ObservedObject var vm: BracketDetailViewModel
    let onEnterSet: (KnockoutMatch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(BracketTheme.seedText)

            ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                KnockoutMatchCard(
                    match: match,
                    gameLabel: "Game \(index + 1)",
                    vm: vm,
                    onEnterSet: onEnterSet
                )
            }
        }
    }
}

// MARK: - Match card

private struct KnockoutMatchCard: View {
    let match: KnockoutMatch
    let gameLabel: String
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
            TeamRow(
                teamID: match.teamAID,
                scores: match.sets.map(\.teamAScore),
                isWinner: match.winnerTeamID != nil && match.winnerTeamID == match.teamAID,
                vm: vm
            )
            Divider().background(BracketTheme.seedText.opacity(0.15))
            if isBye {
                ByeRow()
            } else {
                TeamRow(
                    teamID: match.teamBID,
                    scores: match.sets.map(\.teamBScore),
                    isWinner: match.winnerTeamID != nil && match.winnerTeamID == match.teamBID,
                    vm: vm
                )
            }

            if canEnter {
                footer(text: "Tap to enter a set · Best of \(vm.knockoutBestOf)", systemImage: "plus.circle.fill", tint: BracketTheme.primary)
            } else if isBye {
                footer(text: "Bye — auto-advances", systemImage: "arrow.right.circle", tint: BracketTheme.seedText)
            }
        }
        .background(BracketTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: BracketTheme.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .overlay(alignment: .topTrailing) {
            Text(gameLabel)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(BracketTheme.seedText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
        }
    }

    private func footer(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
            Spacer()
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(tint.opacity(0.06))
    }
}

private struct TeamRow: View {
    let teamID: String?
    let scores: [Int]
    let isWinner: Bool
    @ObservedObject var vm: BracketDetailViewModel

    var body: some View {
        HStack(spacing: 10) {
            if let seed = vm.seedLabel(for: teamID) {
                Text(seed)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BracketTheme.seedText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BracketTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(vm.teamName(teamID))
                .font(.system(size: 15, weight: isWinner ? .semibold : .regular))
                .foregroundStyle(isWinner ? BracketTheme.textPrimary : BracketTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            if isWinner {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(BracketTheme.winner)
            }

            ForEach(Array(scores.enumerated()), id: \.offset) { _, score in
                Text("\(score)")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isWinner ? BracketTheme.winner : BracketTheme.textSecondary)
                    .frame(minWidth: 22)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct ByeRow: View {
    var body: some View {
        HStack {
            Text("BYE")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BracketTheme.seedText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Champion banner

private struct ChampionBanner: View {
    let teamName: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(BracketTheme.champion)

            Text("CHAMPION")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundStyle(BracketTheme.textSecondary)

            Text(teamName)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(BracketTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [BracketTheme.champion.opacity(0.18), BracketTheme.energy.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(BracketTheme.champion.opacity(0.35), lineWidth: 1)
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
        case .thirdPlace:   return "3rd Place Match"
        }
    }
}

// MARK: - Athletic Pro tokens (locked design lane)

private enum BracketTheme {
    static let primary       = Color(red: 0.118, green: 0.251, blue: 0.686) // #1E40AF cobalt
    static let winner        = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981 emerald
    static let champion      = Color(red: 0.980, green: 0.800, blue: 0.082) // #FACC15 gold
    static let energy        = Color(red: 0.984, green: 0.573, blue: 0.235) // #FB923C orange
    static let surface       = Color(red: 0.980, green: 0.980, blue: 0.976) // #FAFAF9
    static let card          = Color.white
    static let textPrimary   = Color(red: 0.059, green: 0.090, blue: 0.165) // #0F172A
    static let textSecondary = Color(red: 0.392, green: 0.455, blue: 0.545) // #64748B
    static let seedText      = Color(red: 0.392, green: 0.455, blue: 0.545)
    static let cardRadius: CGFloat = 16
}
