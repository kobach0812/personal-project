import Foundation

// MARK: - BracketTournament

/// A bracket tournament lives inside a parent `Tournament` (subcollection on the tournament doc).
/// Flow: groupStage (round-robin per group) → knockout (random pairing, best-of-N) → finished.
struct BracketTournament: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let parentTournamentID: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    var title: String
    var status: BracketStatus
    var groups: [BracketGroup]
    /// Number of sets per knockout match. Set when knockout is configured (1 / 3 / 5).
    var knockoutBestOf: Int
    var knockoutMatches: [KnockoutMatch]
}

enum BracketStatus: String, Codable, Sendable {
    case setup
    case groupStage
    case configuringKnockout
    case knockout
    case finished
}

// MARK: - Group stage

struct BracketGroup: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String                // "A", "B", "C", …
    var teams: [FixedTeam]
    var matches: [GroupMatch]
    /// Top N teams advance to knockout. Set when host configures the knockout phase.
    var advanceCount: Int?
}

struct GroupMatch: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let teamAID: String
    let teamBID: String
    var scoreA: Int?
    var scoreB: Int?
    var winnerTeamID: String?
    var completedAt: Date?
}

// MARK: - Knockout

struct KnockoutMatch: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let round: KnockoutRound
    /// 0-indexed slot within the round, used to wire winners into the next round.
    let position: Int
    /// nil teamBID == bye; teamAID auto-advances.
    var teamAID: String?
    var teamBID: String?
    var sets: [SetScore]
    var winnerTeamID: String?
    var completedAt: Date?
}

enum KnockoutRound: String, Codable, Sendable {
    case quarterfinal
    case semifinal
    case final
    case thirdPlace
}

struct SetScore: Codable, Equatable, Hashable, Sendable {
    var teamAScore: Int
    var teamBScore: Int
}
