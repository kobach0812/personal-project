import SwiftUI
import Testing
import UIKit
@testable import PlaySnapp

/// Renders the redesigned horizontal knockout bracket to PNGs under /tmp so the
/// geometry (column layout + connector lines) can be eyeballed without running the
/// full app flow. Not an assertion test — it exists to produce reviewable images.
@MainActor
struct BracketKnockoutSnapshotTests {

    @Test func renderFinishedBracket() throws {
        try render(
            BracketKnockoutView(vm: BracketPreviewData.finished) { _ in },
            size: CGSize(width: 880, height: 720),
            to: "/tmp/knockout_finished.png"
        )
    }

    @Test func renderLiveBracket() throws {
        try render(
            BracketKnockoutView(vm: BracketPreviewData.live) { _ in },
            size: CGSize(width: 460, height: 520),
            to: "/tmp/knockout_live.png"
        )
    }

    @Test func renderStartBracket() throws {
        try render(
            BracketKnockoutView(vm: BracketPreviewData.start) { _ in },
            size: CGSize(width: 720, height: 460),
            to: "/tmp/knockout_start.png"
        )
    }

    /// Hosts the view in a real key window and captures with `drawHierarchy`, which —
    /// unlike `ImageRenderer` — renders `ScrollView` content faithfully.
    private func render(_ view: some View, size: CGSize, to path: String) throws {
        let bounds = CGRect(origin: .zero, size: size)
        let host = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        host.view.frame = bounds
        host.view.backgroundColor = .clear

        let window = UIWindow(frame: bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        // Let SwiftUI commit a render pass before capturing.
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { _ in
            host.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        let data = try #require(image.pngData(), "PNG encoding failed")
        try data.write(to: URL(fileURLWithPath: path))
    }
}
