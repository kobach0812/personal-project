import SwiftUI
import UIKit

/// Semantic color tokens for the "Athletic Pro" design lane (locked 2026-05-27).
///
/// Each token resolves to a light or dark value automatically via a `UIColor`
/// dynamic provider, so restyled surfaces keep working when the system theme flips.
/// Light values are final (from the design guide); dark values are PROVISIONAL —
/// the doc's proposed dark palette, pending designer sign-off.
///
/// Recolor for white-label B2B contracts by editing this one file.
enum ThemeColor {
    /// Main CTAs, tab-bar active state, focus, links.
    static let primary       = Color(lightHex: 0x1E40AF, darkHex: 0x60A5FA)
    /// Wins, success, score-up — winner emphasis in brackets.
    static let accent        = Color(lightHex: 0x10B981, darkHex: 0x34D399)
    /// Live indicators, streaks, attention badges.
    static let energy        = Color(lightHex: 0xFB923C, darkHex: 0xFDBA74)
    /// Trophy moments only — the M25 champion banner.
    static let champion      = Color(lightHex: 0xFACC15, darkHex: 0xFDE047)
    /// Losses and errors — soft coral, never aggressive red.
    static let loss          = Color(lightHex: 0xF87171, darkHex: 0xFCA5A5)
    /// App background — warm white in light, deep navy in dark. Never pure.
    static let surface       = Color(lightHex: 0xFAFAF9, darkHex: 0x0F172A)
    /// Cards, sheets, modals.
    static let card          = Color(lightHex: 0xFFFFFF, darkHex: 0x1E293B)
    /// Headlines and body text.
    static let textPrimary   = Color(lightHex: 0x0F172A, darkHex: 0xF8FAFC)
    /// Captions, meta, timestamps.
    static let textSecondary = Color(lightHex: 0x64748B, darkHex: 0x94A3B8)
}

extension Color {
    /// Builds a color that resolves per system appearance from two 0xRRGGBB hex values.
    init(lightHex: UInt, darkHex: UInt) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgbHex: traits.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

private extension UIColor {
    convenience init(rgbHex: UInt) {
        self.init(
            red:   CGFloat((rgbHex >> 16) & 0xFF) / 255,
            green: CGFloat((rgbHex >> 8) & 0xFF) / 255,
            blue:  CGFloat(rgbHex & 0xFF) / 255,
            alpha: 1
        )
    }
}
