import Foundation

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

actor FirebaseStorageService: StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        let playID = UUID().uuidString
        let path = StoragePaths.playOriginal(squadID: squadID, playID: playID, mediaType: .photo)
        let ref = Storage.storage().reference(withPath: path)
        let compressed = ImageCompressor.jpegData(from: data) ?? data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(compressed, metadata: metadata)
        return try await ref.downloadURL()
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

    func uploadAvatar(data: Data, userID: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        throw FirebaseIntegrationError.notYetImplemented(
            feature: "Avatar upload to Firebase Storage"
        )
        #else
        throw FirebaseIntegrationError.sdkUnavailable(product: "FirebaseStorage")
        #endif
    }
}
