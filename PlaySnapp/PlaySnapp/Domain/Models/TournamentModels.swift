import Foundation

enum TournamentStatus: String, Codable, Sendable {
    case active
    case finished
}

enum WinnerTeam: String, Codable, Sendable {
    case teamA
    case teamB
}

struct TournamentPlayer: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var userID: String?
    var played: Int
    var wins: Int
    var losses: Int
    /// Monotonic match-counter value when this player last finished a match.
    /// 0 = never played. Lower values = rested longer.
    var lastPlayedAt: Int

    var winRate: Double { played == 0 ? 0 : Double(wins) / Double(played) }
}

struct TournamentMatch: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let court: Int
    let teamA: [String]
    let teamB: [String]
    var winnerTeam: WinnerTeam?
    var teamAScore: Int?
    var teamBScore: Int?
    var completedAt: Date?
}

struct TournamentSession: Identifiable, Codable, Sendable {
    let id: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    var status: TournamentStatus
    var courts: Int
    var players: [TournamentPlayer]
    var currentRound: [TournamentMatch]
    var roundNumber: Int
    /// Monotonically increasing counter — incremented each time a match completes.
    /// Used to stamp `lastPlayedAt` on players so rest priority is ordered.
    var matchCounter: Int
    /// Completed matches in reverse-chronological order (newest first). In-session only; not persisted to Firebase yet.
    var completedMatches: [TournamentMatch]
    /// partnerships[playerID][partnerID] = count of times they've been on the same team
    var partnerships: [String: [String: Int]]
}
