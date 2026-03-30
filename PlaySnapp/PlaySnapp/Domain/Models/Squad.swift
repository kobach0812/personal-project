import Foundation

struct Squad: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var sport: Sport
    var memberIDs: [String]
    var inviteCode: String
    let createdAt: Date
}
