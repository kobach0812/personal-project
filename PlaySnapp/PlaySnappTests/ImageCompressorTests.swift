import Foundation
import Testing
import UIKit
@testable import PlaySnapp

// MARK: - Helpers

private func tinyPNGData() -> Data {
    // 10x10 red square rendered through UIGraphicsImageRenderer → PNG bytes
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
    let image = renderer.image { ctx in
        UIColor.red.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    return image.pngData()!
}

// MARK: - Tests

struct ImageCompressorTests {

    @Test
    func jpegData_returnsNilForInvalidInput() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        let out = ImageCompressor.jpegData(from: garbage)
        #expect(out == nil)
    }

    @Test
    func jpegData_returnsNonEmptyForValidImage() {
        let png = tinyPNGData()
        let jpeg = ImageCompressor.jpegData(from: png, compressionQuality: 0.7)
        #expect(jpeg != nil)
        #expect((jpeg?.count ?? 0) > 0)
    }

    @Test
    func jpegData_higherQualityProducesLargerOutput() {
        // Use a larger image so quality differences are measurable.
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let image = renderer.image { ctx in
            for x in stride(from: 0, to: 200, by: 10) {
                for y in stride(from: 0, to: 200, by: 10) {
                    let c = UIColor(red: CGFloat(x) / 200, green: CGFloat(y) / 200, blue: 0.5, alpha: 1)
                    c.setFill()
                    ctx.fill(CGRect(x: x, y: y, width: 10, height: 10))
                }
            }
        }
        let source = image.pngData()!

        let low  = ImageCompressor.jpegData(from: source, compressionQuality: 0.1)
        let high = ImageCompressor.jpegData(from: source, compressionQuality: 1.0)

        #expect(low != nil && high != nil)
        // Quality 1.0 should never produce fewer bytes than quality 0.1
        #expect((high?.count ?? 0) >= (low?.count ?? 0))
    }
}
