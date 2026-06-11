import SwiftUI

/// Fixed (non-adaptive) brand colors for recap cards. Recap cards are exported
/// images with one canonical dark-navy look — they must render identically
/// in-app, in light mode, and inside `ImageRenderer`, so they bypass the
/// trait-resolved `ThemeColor` tokens on purpose.
enum RecapPalette {
    static let canvas     = Color(red: 0x0F / 255, green: 0x17 / 255, blue: 0x2A / 255)
    static let canvasHigh = Color(red: 0x1E / 255, green: 0x29 / 255, blue: 0x3B / 255)
    static let cobalt     = Color(red: 0x60 / 255, green: 0xA5 / 255, blue: 0xFA / 255)
    static let emerald    = Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)
    static let energy     = Color(red: 0xFD / 255, green: 0xBA / 255, blue: 0x74 / 255)
    static let gold       = Color(red: 0xFD / 255, green: 0xE0 / 255, blue: 0x47 / 255)
    static let text       = Color(red: 0xF8 / 255, green: 0xFA / 255, blue: 0xFC / 255)
    static let meta       = Color(red: 0x94 / 255, green: 0xA3 / 255, blue: 0xB8 / 255)
}

/// Shared building blocks so both recap cards stay visually consistent.

struct RecapEyebrow: View {
    let text: String
    var color: Color = RecapPalette.energy

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .kerning(2)
            .foregroundStyle(color)
            .padding(.horizontal, ThemeSpacing.sm)
            .padding(.vertical, ThemeSpacing.xs)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

struct RecapStatBlock: View {
    let value: String
    let label: String
    var color: Color = RecapPalette.text

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(RecapPalette.meta)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecapFooter: View {
    var body: some View {
        HStack(spacing: ThemeSpacing.xs) {
            Circle()
                .fill(RecapPalette.emerald)
                .frame(width: 6, height: 6)
            Text("PlaySnapp")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(RecapPalette.text)
        }
        .padding(.bottom, ThemeSpacing.lg)
    }
}
