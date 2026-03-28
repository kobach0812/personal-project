import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum ImageCompressor {
    static func jpegData(from data: Data, compressionQuality: CGFloat = 0.7) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            return nil
        }

        return image.jpegData(compressionQuality: compressionQuality)
        #else
        return data
        #endif
    }
}
