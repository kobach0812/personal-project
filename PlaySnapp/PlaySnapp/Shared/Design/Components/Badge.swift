import SwiftUI

/// Pill / chip / badge (design guide Tier 3.5). Used for bracket seed labels and
/// small status tags. `neutral` is the default surface-on-card look; the colored
/// variants tint the background for status emphasis.
struct Badge: View {
    enum Style {
        case neutral   // seed labels, generic tags
        case primary   // scheduled / informational
        case accent    // wins / completed
        case energy    // live / streak
        case loss      // cancelled / error

        var foreground: Color {
            switch self {
            case .neutral: return ThemeColor.textSecondary
            case .primary: return ThemeColor.primary
            case .accent:  return ThemeColor.accent
            case .energy:  return ThemeColor.energy
            case .loss:    return ThemeColor.loss
            }
        }

        var background: Color {
            switch self {
            case .neutral: return ThemeColor.surface
            default:       return foreground.opacity(0.14)
            }
        }
    }

    let text: String
    let style: Style

    init(_ text: String, style: Style = .neutral) {
        self.text = text
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(ThemeFont.meta.weight(.semibold))
            .foregroundStyle(style.foreground)
            .padding(.horizontal, ThemeSpacing.sm - 2)
            .padding(.vertical, ThemeSpacing.xs / 2)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.md))
    }
}
