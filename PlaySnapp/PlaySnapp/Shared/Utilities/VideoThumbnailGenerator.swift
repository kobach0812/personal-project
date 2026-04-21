import AVFoundation
import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum VideoThumbnailGenerator {
    /// Generates a JPEG thumbnail from the first frame of a video file.
    /// Returns nil if the asset has no video track or the frame cannot be decoded.
    static func makeThumbnailData(from fileURL: URL) async -> Data? {
        await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            generator.generateCGImagesAsynchronously(
                forTimes: [NSValue(time: .zero)]
            ) { _, image, _, result, _ in
                guard result == .succeeded, let image else {
                    continuation.resume(returning: nil)
                    return
                }

                #if canImport(UIKit)
                let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.7)
                continuation.resume(returning: data)
                #else
                continuation.resume(returning: nil)
                #endif
            }
        }
    }
}
