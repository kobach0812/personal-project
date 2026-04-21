import Foundation

actor StubStorageService: StorageServicing {
    func uploadPhoto(data: Data, squadID: String) async throws -> URL {
        URL(string: "https://example.com/squads/\(squadID)/photo.jpg")!
    }

    func uploadVideo(fileURL: URL, squadID: String) async throws -> URL {
        URL(string: "https://example.com/squads/\(squadID)/video.mov")!
    }

    func uploadAvatar(data: Data, userID: String) async throws -> URL {
        URL(string: "https://example.com/users/\(userID)/avatar.jpg")!
    }
}
