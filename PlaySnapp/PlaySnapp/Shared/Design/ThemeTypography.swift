import SwiftUI

/// Typography ladder (design guide Tier 1.5). SF Pro Rounded for display/title
/// (the Apple-fitness vibe), SF Pro for body/caption/meta, SF Pro Mono for scores.
///
/// Line-heights from the guide are applied per-`Text` with `.lineSpacing` where it
/// matters; `Font` itself only carries size/weight/design.
enum ThemeFont {
    /// Hero headlines — champion banner, big titles. 32 / Bold / Rounded.
    static let display = Font.system(size: 32, weight: .bold, design: .rounded)
    /// Section headers, screen titles. 20 / Semibold / Rounded.
    static let title   = Font.system(size: 20, weight: .semibold, design: .rounded)
    /// Default text, paragraphs. 15 / Regular.
    static let body    = Font.system(size: 15, weight: .regular)
    /// Labels, timestamps, meta. 12 / Medium.
    static let caption = Font.system(size: 12, weight: .medium)
    /// Tiny labels, footnotes. 11 / Medium.
    static let meta    = Font.system(size: 11, weight: .medium)
    /// Scores, set scores, stats. 15 / Semibold / Monospaced.
    static let numeric = Font.system(size: 15, weight: .semibold, design: .monospaced)
}
