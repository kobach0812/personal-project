import Foundation

struct Squad: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    /// User ID of the member who created the squad. Used for permission checks and display.
    let createdBy: String
    /// In-memory member list used by stubs. The Firebase implementation uses a members subcollection.
    var memberIDs: [String]
    var inviteCode: String
    let createdAt: Date
}
