import Foundation

/// Central registry for Firebase Storage paths.
/// All upload/download operations must use these helpers — never build paths inline.
enum StoragePaths {
    // MARK: - Play media

    static func playOriginal(squadID: String, playID: String, mediaType: MediaType) -> String {
        let filename = mediaType == .photo ? "original.jpg" : "original.mov"
        return "squads/\(squadID)/plays/\(playID)/\(filename)"
    }

    static func playThumbnail(squadID: String, playID: String) -> String {
        "squads/\(squadID)/plays/\(playID)/thumbnail.jpg"
    }

    // MARK: - Avatars

    static func avatar(userID: String) -> String {
        "avatars/\(userID)/avatar.jpg"
    }
}
