import SwiftUI
import UIKit

/// Renders a recap card to a shareable image (M26). The same card view is shown
/// in-app and exported, so the preview always matches the shared PNG.
@MainActor
enum RecapImageRenderer {
    /// Design canvas in points; rendered at 3× → a 1080×1920 px story-format image.
    static let cardSize = CGSize(width: 360, height: 640)

    static func render(_ card: some View) -> UIImage? {
        let renderer = ImageRenderer(
            content: card.frame(width: cardSize.width, height: cardSize.height)
        )
        renderer.scale = 3
        return renderer.uiImage
    }
}
