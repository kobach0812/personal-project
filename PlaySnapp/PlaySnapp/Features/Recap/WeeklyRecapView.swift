import SwiftUI

/// The weekly recap card (M26). Designed at `RecapImageRenderer.cardSize` so the
/// in-app preview is pixel-identical to the exported share image.
///
/// The hero photo is passed in pre-loaded — `AsyncImage` never resolves inside
/// `ImageRenderer`, so the view model fetches the top play's thumbnail up front.
struct WeeklyRecapView: View {
    let recap: SquadRecap
    let heroImage: UIImage?

    private var dateRange: String {
        let style = Date.FormatStyle().month(.abbreviated).day()
        return "\(recap.weekStart.formatted(style)) – \(recap.weekEnd.formatted(style))"
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
            stats
            highlights
            Spacer(minLength: ThemeSpacing.md)
            RecapFooter()
        }
        .frame(width: RecapImageRenderer.cardSize.width, height: RecapImageRenderer.cardSize.height)
        .background(RecapPalette.canvas)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let heroImage {
                    Image(uiImage: heroImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [RecapPalette.cobalt.opacity(0.55), RecapPalette.canvas],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "sportscourt")
                            .font(.system(size: 72, weight: .light))
                            .foregroundStyle(RecapPalette.cobalt.opacity(0.5))
                    )
                }
            }
            .frame(width: RecapImageRenderer.cardSize.width, height: 320)
            .clipped()

            LinearGradient(
                colors: [.clear, RecapPalette.canvas.opacity(0.65), RecapPalette.canvas],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 320)

            VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                RecapEyebrow(text: "WEEKLY RECAP")
                Text(recap.squadName)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(RecapPalette.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(dateRange)
                    .font(ThemeFont.caption)
                    .foregroundStyle(RecapPalette.meta)
            }
            .padding(ThemeSpacing.xl)
        }
        .frame(height: 320)
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: 0) {
            RecapStatBlock(value: "\(recap.playCount)", label: "Plays")
            Rectangle()
                .fill(RecapPalette.meta.opacity(0.25))
                .frame(width: 1, height: 44)
            RecapStatBlock(value: "\(recap.reactionCount)", label: "Reactions", color: RecapPalette.emerald)
        }
        .padding(.horizontal, ThemeSpacing.xl)
        .padding(.top, ThemeSpacing.sm)
    }

    // MARK: - Highlights

    private var highlights: some View {
        VStack(spacing: ThemeSpacing.sm) {
            if let poster = recap.topPosterName {
                highlightRow(icon: "bolt.fill", iconColor: RecapPalette.energy,
                             label: "Most active", value: poster)
            }
            if let topPlay = recap.topPlay {
                let reactions = topPlay.reactionSummary.values.reduce(0, +)
                highlightRow(icon: "flame.fill", iconColor: RecapPalette.emerald,
                             label: "Top play",
                             value: reactions > 0
                                ? "\(topPlay.senderName) · \(reactions) reactions"
                                : topPlay.senderName)
            }
        }
        .padding(.horizontal, ThemeSpacing.xl)
        .padding(.top, ThemeSpacing.lg)
    }

    private func highlightRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
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
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(RecapPalette.text)
                .lineLimit(1)
        }
        .padding(ThemeSpacing.md)
        .background(RecapPalette.canvasHigh)
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.lg))
    }
}

#Preview("With photo placeholder") {
    WeeklyRecapView(
        recap: SquadRecap(
            squadName: "Tuesday Pickleball",
            weekStart: .now.addingTimeInterval(-7 * 86_400),
            weekEnd: .now,
            playCount: 12,
            reactionCount: 47,
            topPosterName: "Alice",
            topPlay: AppFixtures.samplePlays.first
        ),
        heroImage: nil
    )
}
