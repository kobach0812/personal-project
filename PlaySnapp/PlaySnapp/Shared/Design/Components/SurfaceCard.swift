import SwiftUI

/// Card surface (design guide Tier 3.4): white card on the warm-white app surface,
/// radius `xl`, mid elevation. Applied as a modifier so callers keep full control of
/// their internal layout (knockout cards stack custom rows + a footer inside this).
struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ThemeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xl))
            .themeShadow(.mid)
    }
}

extension View {
    /// Wraps the view in the standard Athletic Pro card surface.
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}
