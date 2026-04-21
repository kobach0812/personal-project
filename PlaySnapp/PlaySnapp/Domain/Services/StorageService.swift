import Foundation

protocol StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL
    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL
    /// Uploads a user avatar and returns the download URL.
    /// Callers should then pass the URL to UserProfileServicing.updateAvatar(url:).
    func uploadAvatar(data: Data, userID: String) async throws -> URL
}
