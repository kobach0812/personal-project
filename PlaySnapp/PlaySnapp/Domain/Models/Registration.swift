import Foundation

enum RegistrationStatus: String, Codable, Sendable {
    case yes
    case maybe
    case no
}

struct Registration: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// doc ID == userID for dedup
    let id: String
    let userID: String
    var name: String
    var status: RegistrationStatus
    let registeredAt: Date
    /// Stamped by host when they tap check-in. Nil = not yet checked in.
    var checkedInAt: Date?
    /// True once this registration has been pulled into session.players[].
    var addedToRoster: Bool
}
