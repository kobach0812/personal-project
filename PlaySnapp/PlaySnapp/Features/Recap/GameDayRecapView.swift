import SwiftUI

/// The game day recap card (M26). Two treatments from one layout:
/// the standard navy day summary, and the gold champion variant when a
/// bracket final has crowned a winner (`championTeamName != nil`).
struct GameDayRecapView: View {
    let recap: GameDayRecap

    private var isChampion: Bool { recap.championTeamName != nil }
    private var accent: Color { isChampion ? RecapPalette.gold : RecapPalette.energy }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: ThemeSpacing.xxl)
            header
            Spacer(minLength: ThemeSpacing.xl)
            stats
            highlights
            Spacer(minLength: ThemeSpacing.md)
            RecapFooter()
        }
        .frame(width: RecapImageRenderer.cardSize.width, height: RecapImageRenderer.cardSize.height)
        .background(background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: ThemeSpacing.md) {
            Image(systemName: isChampion ? "trophy.fill" : "figure.badminton")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(accent)
                .padding(ThemeSpacing.xl)
                .background(accent.opacity(0.12))
                .clipShape(Circle())

            RecapEyebrow(text: isChampion ? "CHAMPION" : "GAME DAY RECAP", color: accent)

            if let champion = recap.championTeamName {
                Text(champion)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(RecapPalette.gold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(recap.gameTitle)
                    .font(ThemeFont.title)
                    .foregroundStyle(RecapPalette.text)
                    .lineLimit(1)
            } else {
                Text(recap.gameTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(RecapPalette.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            Text(recap.date.formatted(date: .abbreviated, time: .shortened))
                .font(ThemeFont.caption)
                .foregroundStyle(RecapPalette.meta)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, ThemeSpacing.xl)
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: 0) {
            RecapStatBlock(value: "\(recap.playerCount)", label: "Players")
            Rectangle()
                .fill(RecapPalette.meta.opacity(0.25))
                .frame(width: 1, height: 44)
            RecapStatBlock(value: "\(recap.matchCount)", label: "Matches", color: RecapPalette.cobalt)
        }
        .padding(.horizontal, ThemeSpacing.xl)
    }

    // MARK: - Highlights

    private var highlights: some View {
        VStack(spacing: ThemeSpacing.sm) {
            if let performer = recap.topPerformerName {
                highlightRow(icon: "medal.fill", iconColor: RecapPalette.emerald,
                             label: "Top performer", value: performer)
            }
            if let scoreline = recap.biggestScoreline {
                highlightRow(icon: "chart.bar.fill", iconColor: RecapPalette.cobalt,
                             label: "Biggest win", value: scoreline, monospaced: true)
            }
        }
        .padding(.horizontal, ThemeSpacing.xl)
        .padding(.top, ThemeSpacing.lg)
    }

    private func highlightRow(
        icon: String, iconColor: Color, label: String, value: String, monospaced: Bool = false
    ) -> some View {
        HStack(spacing: ThemeSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.14))
                .clipShape(Circle())
            Text(label)
                .font(ThemeFont.caption)
                .foregroundStyle(RecapPalette.meta)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: monospaced ? .monospaced : .rounded))
                .foregroundStyle(RecapPalette.text)
                .lineLimit(1)
        }
        .padding(ThemeSpacing.md)
        .background(RecapPalette.canvasHigh)
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.lg))
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            RecapPalette.canvas
            RadialGradient(
                colors: [accent.opacity(isChampion ? 0.18 : 0.10), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0, endRadius: 320
            )
        }
    }
}

#Preview("Day recap") {
    GameDayRecapView(recap: GameDayRecap(
        gameTitle: "Tuesday 8pm",
        date: .now,
        playerCount: 9,
        matchCount: 14,
        topPerformerName: "Alice",
        biggestScoreline: "21–9",
        championTeamName: nil
    ))
}

#Preview("Champion") {
    GameDayRecapView(recap: GameDayRecap(
        gameTitle: "Spring Cup",
        date: .now,
        playerCount: 12,
        matchCount: 11,
        topPerformerName: nil,
        biggestScoreline: nil,
        championTeamName: "Team Alice & Bob"
    ))
}
