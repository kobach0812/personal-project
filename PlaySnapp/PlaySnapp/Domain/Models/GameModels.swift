import Foundation

enum SessionMode: String, Codable, Sendable {
    case rotation   // fair-play rotation (default)
    case fixedTeams // round-robin between pre-defined pairs
}

struct FixedTeam: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String        // "Team 1", "Team 2" … (auto-assigned)
    var playerIDs: [String] // exactly 2 for doubles
}

enum GameStatus: String, Codable, Sendable {
    case scheduled
    case active
    case finished
    case cancelled
}

enum WinnerTeam: String, Codable, Sendable {
    case teamA
    case teamB
}

struct GamePlayer: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var userID: String?
    var played: Int
    var wins: Int
    var losses: Int
    /// Monotonic match-counter value when this player last finished a match.
    /// 0 = never played. Lower values = rested longer.
    var lastPlayedAt: Int
    /// false = benched — excluded from rotation but kept on the roster and board.
    var isActive: Bool

    var winRate: Double { played == 0 ? 0 : Double(wins) / Double(played) }
}

struct GameMatch: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let court: Int
    let teamA: [String]
    let teamB: [String]
    var winnerTeam: WinnerTeam?
    var teamAScore: Int?
    var teamBScore: Int?
    var completedAt: Date?
}

// MARK: - Game (parent)

/// Named series, e.g. "Tuesday Badminton". Contains one or many play days (sessions).
struct Game: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    var title: String
    var status: GameStatus
    /// Roster + cumulative stats that are summed when each day ends.
    var players: [GamePlayer]
    /// ID of the currently active day session, if any.
    var activeDayID: String?
    /// Loaded on demand — NOT stored in Firestore.
    var sessions: [GameSession]
}

// MARK: - GameSession (one play day)

/// One play day within a Game.
struct GameSession: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let gameID: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    /// Display label for this day, e.g. "Day 3" or "Apr 24".
    var title: String
    var status: GameStatus
    var courts: Int
    /// Day-specific player stats + isActive flag for that day's rotation.
    var players: [GamePlayer]
    var currentRound: [GameMatch]
    var roundNumber: Int
    /// Monotonically increasing counter — incremented each time a match completes.
    var matchCounter: Int
    /// Completed matches, newest first. Populated from the Firestore `matches` subcollection on load.
    var completedMatches: [GameMatch]
    /// partnerships[playerID][partnerID] = count of times they've been on the same team.
    var partnerships: [String: [String: Int]]
    /// User IDs of all roster-added participants. Used for participant live-view.
    var participantUserIDs: [String]
    /// Set when the day is ended. Used to compute duration in the Summary tab.
    var endedAt: Date?
    /// Nil for walk-up sessions. Set for pre-scheduled days.
    var scheduledStart: Date?
    /// Optional free-text location, e.g. "Court 3, Eastern Park".
    var location: String?
    /// Session scheduling mode — rotation (default) or fixed-teams round-robin.
    var mode: SessionMode
    /// Pre-defined fixed pairs. Non-empty only when mode == .fixedTeams.
    var fixedTeams: [FixedTeam]
}
