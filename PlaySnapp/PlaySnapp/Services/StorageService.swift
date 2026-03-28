import Foundation

protocol StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL
    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL
}

actor StubStorageService: StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL {
        URL(string: "https://example.com/squads/\(squadID)/photo.jpg")!
    }

    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL {
        URL(string: "https://example.com/squads/\(squadID)/video.mov")!
    }
}
