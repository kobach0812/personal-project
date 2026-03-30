import Foundation

protocol StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL
    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL
}
