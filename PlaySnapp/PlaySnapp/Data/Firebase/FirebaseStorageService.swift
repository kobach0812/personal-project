import Foundation

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

actor FirebaseStorageService: StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Photo upload pipeline to Firebase Storage"
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseStorage")
        #endif
    }

    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Video upload pipeline to Firebase Storage"
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseStorage")
        #endif
    }
}
