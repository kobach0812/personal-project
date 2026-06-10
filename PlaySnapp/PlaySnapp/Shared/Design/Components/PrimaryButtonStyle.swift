import SwiftUI

/// Primary CTA button (design guide Tier 3.1): full-width cobalt, white text,
/// radius `lg`, with a press scale-down. Disabled handling is left to `.disabled()`
/// (SwiftUI dims it), matching the existing call sites.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeFont.title.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.lg - 2)
            .background(ThemeColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.lg))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
