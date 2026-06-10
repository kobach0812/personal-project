// MoodboardSamples.swift
//
// Side-by-side preview of four candidate visual moods for PlaySnapp.
// Open in Xcode → click the Canvas pane → swipe between mood pages.
// This file is exploratory only — NOT wired into the app navigation,
// no impact on production. Delete the file when a direction is locked.

import SwiftUI

// MARK: - Mood Tokens

/// A single mood's design tokens. Everything that visually changes between moods
/// lives here; the sample surfaces below consume this struct.
struct MoodTokens {
    let name: String
    let tagline: String

    // Colors
    let primary: Color
    let accent: Color
    let energy: Color
    let champion: Color
    let loss: Color
    let surface: Color
    let card: Color
    let textPrimary: Color
    let textSecondary: Color

    // Shape
    let cardCornerRadius: CGFloat
    let buttonCornerRadius: CGFloat
    let pillCornerRadius: CGFloat
    let cardShadowOpacity: Double
    let cardShadowRadius: CGFloat

    // Type
    let displayFont: Font
    let titleFont: Font
    let bodyFont: Font
    let captionFont: Font
    let numericFont: Font

    // Layout
    let cardPadding: CGFloat
    let cardSpacing: CGFloat
}

extension MoodTokens {

    // MARK: Mood 1 — Athletic Pro (Strava / Hudl lane)

    static let athleticPro = MoodTokens(
        name: "Athletic Pro",
        tagline: "Strava / Hudl lane — global sport SaaS energy",

        primary:        Color(red: 0.118, green: 0.251, blue: 0.686), // #1E40AF cobalt
        accent:         Color(red: 0.063, green: 0.725, blue: 0.506), // #10B981 emerald
        energy:         Color(red: 0.984, green: 0.573, blue: 0.235), // #FB923C orange
        champion:       Color(red: 0.980, green: 0.800, blue: 0.082), // #FACC15 gold
        loss:           Color(red: 0.973, green: 0.443, blue: 0.443), // #F87171 coral
        surface:        Color(red: 0.980, green: 0.980, blue: 0.976), // #FAFAF9 warm white
        card:           .white,
        textPrimary:    Color(red: 0.059, green: 0.090, blue: 0.165), // #0F172A
        textSecondary:  Color(red: 0.392, green: 0.455, blue: 0.545), // #64748B slate

        cardCornerRadius: 16,
        buttonCornerRadius: 14,
        pillCornerRadius: 8,
        cardShadowOpacity: 0.06,
        cardShadowRadius: 12,

        displayFont: .system(size: 32, weight: .bold, design: .rounded),
        titleFont:   .system(size: 20, weight: .semibold, design: .rounded),
        bodyFont:    .system(size: 15, weight: .regular),
        captionFont: .system(size: 12, weight: .medium),
        numericFont: .system(size: 15, weight: .semibold, design: .monospaced),

        cardPadding: 16,
        cardSpacing: 12
    )

    // MARK: Mood 2 — Friendly Squad (BeReal / Houseparty lane)

    static let friendlySquad = MoodTokens(
        name: "Friendly Squad",
        tagline: "BeReal / Houseparty — your squad's warm clubhouse",

        primary:        Color(red: 0.937, green: 0.278, blue: 0.435), // #EF476F coral
        accent:         Color(red: 0.024, green: 0.714, blue: 0.831), // #06B6D4 teal
        energy:         Color(red: 0.988, green: 0.827, blue: 0.302), // #FCD34D sunshine
        champion:       Color(red: 0.984, green: 0.573, blue: 0.235), // #FB923C warm orange
        loss:           Color(red: 0.580, green: 0.639, blue: 0.722), // #94A3B8 muted slate
        surface:        Color(red: 1.000, green: 0.976, blue: 0.941), // #FFF9F0 cream
        card:           .white,
        textPrimary:    Color(red: 0.118, green: 0.106, blue: 0.180), // #1E1B2E plum
        textSecondary:  Color(red: 0.580, green: 0.639, blue: 0.722), // #94A3B8

        cardCornerRadius: 20,
        buttonCornerRadius: 20,
        pillCornerRadius: 12,
        cardShadowOpacity: 0.10,
        cardShadowRadius: 16,

        displayFont: .system(size: 34, weight: .heavy, design: .rounded),
        titleFont:   .system(size: 22, weight: .bold, design: .rounded),
        bodyFont:    .system(size: 16, weight: .regular, design: .rounded),
        captionFont: .system(size: 13, weight: .semibold, design: .rounded),
        numericFont: .system(size: 16, weight: .bold, design: .rounded),

        cardPadding: 18,
        cardSpacing: 14
    )

    // MARK: Mood 3 — Modern Court (ALD / New Balance lane)

    static let modernCourt = MoodTokens(
        name: "Modern Court",
        tagline: "Aimé Leon Dore / New Balance — sport-heritage, refined",

        primary:        Color(red: 0.122, green: 0.239, blue: 0.169), // #1F3D2B forest
        accent:         Color(red: 0.831, green: 0.647, blue: 0.455), // #D4A574 mustard
        energy:         Color(red: 0.784, green: 0.294, blue: 0.192), // #C84B31 brick
        champion:       Color(red: 0.831, green: 0.647, blue: 0.455), // #D4A574 same mustard
        loss:           Color(red: 0.545, green: 0.271, blue: 0.075), // #8B4513 saddle
        surface:        Color(red: 0.961, green: 0.937, blue: 0.898), // #F5EFE5 parchment
        card:           Color(red: 0.980, green: 0.965, blue: 0.933), // #FAF6EE cream
        textPrimary:    Color(red: 0.102, green: 0.102, blue: 0.102), // #1A1A1A
        textSecondary:  Color(red: 0.420, green: 0.388, blue: 0.345), // #6B6358 taupe

        cardCornerRadius: 12,
        buttonCornerRadius: 8,
        pillCornerRadius: 4,
        cardShadowOpacity: 0.0, // flat with border instead
        cardShadowRadius: 0,

        displayFont: .system(size: 38, weight: .bold, design: .serif),
        titleFont:   .system(size: 22, weight: .semibold, design: .serif),
        bodyFont:    .system(size: 15, weight: .regular),
        captionFont: .system(size: 11, weight: .semibold).smallCaps(),
        numericFont: .system(size: 18, weight: .regular, design: .monospaced),

        cardPadding: 20,
        cardSpacing: 16
    )

    // MARK: Mood 4 — Tech Hype (Linear / Vercel lane)

    static let techHype = MoodTokens(
        name: "Tech Hype",
        tagline: "Linear / Vercel / Riot — sharp, gamer-adjacent",

        primary:        .black,                                         // #000000
        accent:         Color(red: 0.224, green: 1.000, blue: 0.078),   // #39FF14 neon
        energy:         Color(red: 0.231, green: 0.510, blue: 0.965),   // #3B82F6 electric
        champion:       Color(red: 0.224, green: 1.000, blue: 0.078),   // neon same
        loss:           Color(red: 0.937, green: 0.267, blue: 0.267),   // #EF4444 sharp red
        surface:        Color(red: 0.957, green: 0.957, blue: 0.961),   // #F4F4F5
        card:           .white,
        textPrimary:    Color(red: 0.094, green: 0.094, blue: 0.106),   // #18181B
        textSecondary:  Color(red: 0.443, green: 0.443, blue: 0.478),   // #71717A

        cardCornerRadius: 4,
        buttonCornerRadius: 4,
        pillCornerRadius: 2,
        cardShadowOpacity: 0.12,
        cardShadowRadius: 4, // sharper, smaller

        displayFont: .system(size: 32, weight: .black),
        titleFont:   .system(size: 18, weight: .bold),
        bodyFont:    .system(size: 14, weight: .regular),
        captionFont: .system(size: 11, weight: .medium, design: .monospaced),
        numericFont: .system(size: 16, weight: .bold, design: .monospaced),

        cardPadding: 14,
        cardSpacing: 10
    )
}

// MARK: - Sample surfaces

/// A representative feed card showing a recent match score with photo + reactions.
struct FeedCardSample: View {
    let tokens: MoodTokens

    var body: some View {
        VStack(alignment: .leading, spacing: tokens.cardSpacing) {

            // Header — user + timestamp
            HStack(spacing: 10) {
                Circle()
                    .fill(tokens.primary.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("L")
                            .font(tokens.titleFont)
                            .foregroundStyle(tokens.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Linh")
                        .font(tokens.bodyFont.weight(.semibold))
                        .foregroundStyle(tokens.textPrimary)
                    Text("2h ago · Eagles squad")
                        .font(tokens.captionFont)
                        .foregroundStyle(tokens.textSecondary)
                }

                Spacer()
            }

            // Photo placeholder
            ZStack {
                LinearGradient(
                    colors: [tokens.primary.opacity(0.7), tokens.accent.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: tokens.cardCornerRadius - 4))

            // Score row
            HStack(spacing: 10) {
                Text("21–15")
                    .font(tokens.numericFont)
                    .foregroundStyle(tokens.textPrimary)

                Text("WIN")
                    .font(tokens.captionFont.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tokens.accent)
                    .clipShape(RoundedRectangle(cornerRadius: tokens.pillCornerRadius))

                Text("vs Team B")
                    .font(tokens.captionFont)
                    .foregroundStyle(tokens.textSecondary)

                Spacer()
            }

            // Reactions
            HStack(spacing: 14) {
                ReactionPill(emoji: "🔥", count: 3, tokens: tokens)
                ReactionPill(emoji: "👏", count: 5, tokens: tokens)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 12))
                    Text("2")
                        .font(tokens.captionFont)
                }
                .foregroundStyle(tokens.textSecondary)
            }
        }
        .padding(tokens.cardPadding)
        .background(tokens.card)
        .clipShape(RoundedRectangle(cornerRadius: tokens.cardCornerRadius))
        .shadow(
            color: .black.opacity(tokens.cardShadowOpacity),
            radius: tokens.cardShadowRadius,
            x: 0,
            y: 4
        )
        .overlay(
            // Mood 3 (Modern Court) uses border instead of shadow
            RoundedRectangle(cornerRadius: tokens.cardCornerRadius)
                .strokeBorder(
                    tokens.cardShadowOpacity == 0
                        ? tokens.textPrimary.opacity(0.15)
                        : .clear,
                    lineWidth: 0.5
                )
        )
    }
}

private struct ReactionPill: View {
    let emoji: String
    let count: Int
    let tokens: MoodTokens

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
            Text("\(count)")
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: tokens.pillCornerRadius))
    }
}

/// A champion banner — the big visual moment when a bracket finishes.
struct ChampionBannerSample: View {
    let tokens: MoodTokens

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(tokens.champion)

            Text("CHAMPION")
                .font(tokens.captionFont.weight(.bold))
                .tracking(2)
                .foregroundStyle(tokens.textSecondary)

            Text("Team Eagles")
                .font(tokens.displayFont)
                .foregroundStyle(tokens.textPrimary)

            Text("2026 Spring Bracket")
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(tokens.cardPadding + 8)
        .background(
            LinearGradient(
                colors: [
                    tokens.champion.opacity(0.15),
                    tokens.energy.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: tokens.cardCornerRadius + 4))
        .overlay(
            RoundedRectangle(cornerRadius: tokens.cardCornerRadius + 4)
                .strokeBorder(tokens.champion.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Primary CTA button — the "main action" style for any mood.
struct PrimaryButtonSample: View {
    let tokens: MoodTokens
    let title: String

    var body: some View {
        Text(title)
            .font(tokens.titleFont.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tokens.primary)
            .clipShape(RoundedRectangle(cornerRadius: tokens.buttonCornerRadius))
    }
}

/// A compact bracket match card — what knockout matches will look like in M25.
struct BracketCardSample: View {
    let tokens: MoodTokens

    var body: some View {
        VStack(spacing: 0) {
            BracketTeamRow(name: "Team Eagles", seed: "A1", scores: [21, 18], isWinner: true, tokens: tokens)
            Divider()
                .background(tokens.textSecondary.opacity(0.2))
            BracketTeamRow(name: "Team Hawks",  seed: "B2", scores: [17, 21, 15], isWinner: false, tokens: tokens)
        }
        .background(tokens.card)
        .clipShape(RoundedRectangle(cornerRadius: tokens.cardCornerRadius))
        .shadow(
            color: .black.opacity(tokens.cardShadowOpacity),
            radius: tokens.cardShadowRadius,
            x: 0, y: 2
        )
        .overlay(
            RoundedRectangle(cornerRadius: tokens.cardCornerRadius)
                .strokeBorder(
                    tokens.cardShadowOpacity == 0
                        ? tokens.textPrimary.opacity(0.15)
                        : .clear,
                    lineWidth: 0.5
                )
        )
    }
}

private struct BracketTeamRow: View {
    let name: String
    let seed: String
    let scores: [Int]
    let isWinner: Bool
    let tokens: MoodTokens

    var body: some View {
        HStack(spacing: 10) {
            Text(name)
                .font(isWinner ? tokens.bodyFont.weight(.semibold) : tokens.bodyFont)
                .foregroundStyle(isWinner ? tokens.textPrimary : tokens.textSecondary)

            Text(seed)
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: tokens.pillCornerRadius))

            Spacer()

            ForEach(Array(scores.enumerated()), id: \.offset) { _, score in
                Text("\(score)")
                    .font(tokens.numericFont)
                    .foregroundStyle(isWinner ? tokens.accent : tokens.textSecondary)
                    .frame(minWidth: 24)
            }
        }
        .padding(.horizontal, tokens.cardPadding)
        .padding(.vertical, 10)
    }
}

/// Empty state — important because empty states are first-impression moments.
struct EmptyStateSample: View {
    let tokens: MoodTokens

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tokens.primary.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "sportscourt")
                    .font(.system(size: 36))
                    .foregroundStyle(tokens.primary)
            }

            Text("No plays yet")
                .font(tokens.titleFont)
                .foregroundStyle(tokens.textPrimary)

            Text("Your squad's first post will appear here.")
                .font(tokens.bodyFont)
                .foregroundStyle(tokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(tokens.cardPadding + 8)
    }
}

// MARK: - Mood page

/// One full page showing all sample surfaces for a single mood.
struct MoodPage: View {
    let tokens: MoodTokens

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Mood header
                VStack(alignment: .leading, spacing: 4) {
                    Text(tokens.name)
                        .font(tokens.displayFont)
                        .foregroundStyle(tokens.textPrimary)
                    Text(tokens.tagline)
                        .font(tokens.captionFont)
                        .foregroundStyle(tokens.textSecondary)
                }
                .padding(.horizontal, 20)

                // Palette swatches
                paletteStrip
                    .padding(.horizontal, 20)

                Divider()

                // Feed card sample
                surface(label: "Feed card", view: FeedCardSample(tokens: tokens))

                // Bracket card sample
                surface(label: "Bracket match card", view: BracketCardSample(tokens: tokens))

                // Champion banner
                surface(label: "Champion banner", view: ChampionBannerSample(tokens: tokens))

                // Primary CTA
                surface(label: "Primary button", view: PrimaryButtonSample(tokens: tokens, title: "Start Game Day"))

                // Empty state
                surface(label: "Empty state", view: EmptyStateSample(tokens: tokens))

                Spacer(minLength: 40)
            }
            .padding(.vertical, 20)
        }
        .background(tokens.surface.ignoresSafeArea())
    }

    @ViewBuilder
    private func surface<V: View>(label: String, view: V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(tokens.textSecondary)
                .padding(.horizontal, 20)
            view
                .padding(.horizontal, 20)
        }
    }

    private var paletteStrip: some View {
        HStack(spacing: 6) {
            swatch(tokens.primary,  label: "Primary")
            swatch(tokens.accent,   label: "Accent")
            swatch(tokens.energy,   label: "Energy")
            swatch(tokens.champion, label: "Champ")
            swatch(tokens.loss,     label: "Loss")
        }
    }

    private func swatch(_ color: Color, label: String) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(height: 40)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(tokens.textSecondary)
        }
    }
}

// MARK: - Top-level showcase

/// The root showcase view — paged tabs let you swipe between moods.
/// In Xcode Canvas, scroll vertically within a mood, swipe horizontally between moods.
struct MoodboardSamples: View {

    private let moods: [MoodTokens] = [
        .athleticPro,
        .friendlySquad,
        .modernCourt,
        .techHype
    ]

    @State private var selection: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator + label
            HStack {
                Text("Mood \(selection + 1) of \(moods.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                ForEach(moods.indices, id: \.self) { i in
                    Circle()
                        .fill(selection == i ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)

            // Paged moods
            TabView(selection: $selection) {
                ForEach(moods.indices, id: \.self) { i in
                    MoodPage(tokens: moods[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// MARK: - Previews

#Preview("All moods · light", traits: .sizeThatFitsLayout) {
    MoodboardSamples()
        .frame(width: 390, height: 844) // iPhone 15/17 Pro size
        .preferredColorScheme(.light)
}

#Preview("All moods · dark", traits: .sizeThatFitsLayout) {
    MoodboardSamples()
        .frame(width: 390, height: 844)
        .preferredColorScheme(.dark)
}

#Preview("Mood 1 Athletic Pro") {
    MoodPage(tokens: .athleticPro)
}

#Preview("Mood 2 Friendly Squad") {
    MoodPage(tokens: .friendlySquad)
}

#Preview("Mood 3 Modern Court") {
    MoodPage(tokens: .modernCourt)
}

#Preview("Mood 4 Tech Hype") {
    MoodPage(tokens: .techHype)
}
