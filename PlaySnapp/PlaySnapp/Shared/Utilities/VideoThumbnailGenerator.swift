import AVFoundation
import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum VideoThumbnailGenerator {
    static func makeThumbnailData(from fileURL: URL) -> Data? {
        let asset = AVURLAsset(url: fileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let semaphore = DispatchSemaphore(value: 0)
        var thumbnailData: Data?

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, image, _, result, _ in
            defer {
                semaphore.signal()
            }

            guard result == .succeeded, let image else {
                return
            }

            #if canImport(UIKit)
            thumbnailData = UIImage(cgImage: image).jpegData(compressionQuality: 0.7)
            #endif
        }

        _ = semaphore.wait(timeout: .now() + 5)
        return thumbnailData
    }
}
