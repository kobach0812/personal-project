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

        do {
            let image = try generator.copyCGImage(at: .zero, actualTime: nil)
            #if canImport(UIKit)
            return UIImage(cgImage: image).jpegData(compressionQuality: 0.7)
            #else
            return nil
            #endif
        } catch {
            return nil
        }
    }
}
