import SwiftUI

/// Numeric score display (design guide Tier 3.14). Monospaced so digits align in
/// rows and standings. `emphasized` is the winner treatment — emerald accent.
struct ScoreText: View {
    let text: String
    var emphasized: Bool = false

    init(_ text: String, emphasized: Bool = false) {
        self.text = text
        self.emphasized = emphasized
    }

    var body: some View {
        Text(text)
            .font(ThemeFont.numeric)
            .foregroundStyle(emphasized ? ThemeColor.accent : ThemeColor.textSecondary)
    }
}
