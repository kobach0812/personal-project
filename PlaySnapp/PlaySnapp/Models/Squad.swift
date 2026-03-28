import Foundation

struct Squad: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var sport: Sport
    var memberIDs: [String]
    var inviteCode: String
    let createdAt: Date
}

extension Squad {
    nonisolated static let sample = Squad(
        id: "squad-1",
        name: "Tuesday Five-a-Side",
        sport: .football,
        memberIDs: ["user-1", "user-2", "user-3"],
        inviteCode: "PLAY5",
        createdAt: .now
    )
}
