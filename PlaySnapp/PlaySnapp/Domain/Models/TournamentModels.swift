import Foundation

enum TournamentStatus: String, Codable, Sendable {
    case active
    case finished
}

enum WinnerTeam: String, Codable, Sendable {
    case teamA
    case teamB
}

struct TournamentPlayer: Identifiable, Codable, Equatable, Hashable, Sendable {
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

struct TournamentMatch: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let court: Int
    let teamA: [String]
    let teamB: [String]
    var winnerTeam: WinnerTeam?
    var teamAScore: Int?
    var teamBScore: Int?
    var completedAt: Date?
}

// MARK: - Tournament (parent)

/// Named series, e.g. "Tuesday Badminton". Contains one or many play days (sessions).
struct Tournament: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    var title: String
    var status: TournamentStatus
    /// Roster + cumulative stats that are summed when each day ends.
    var players: [TournamentPlayer]
    /// ID of the currently active day session, if any.
    var activeDayID: String?
    /// Loaded on demand — NOT stored in Firestore.
    var sessions: [TournamentSession]
}

// MARK: - TournamentSession (one play day)

/// One play day within a Tournament.
struct TournamentSession: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let tournamentID: String
    let squadID: String
    let createdBy: String
    let createdAt: Date
    /// Display label for this day, e.g. "Day 3" or "Apr 24".
    var title: String
    var status: TournamentStatus
    var courts: Int
    /// Day-specific player stats + isActive flag for that day's rotation.
    var players: [TournamentPlayer]
    var currentRound: [TournamentMatch]
    var roundNumber: Int
    /// Monotonically increasing counter — incremented each time a match completes.
    var matchCounter: Int
    /// Completed matches, newest first. Populated from the Firestore `matches` subcollection on load.
    var completedMatches: [TournamentMatch]
    /// partnerships[playerID][partnerID] = count of times they've been on the same team.
    var partnerships: [String: [String: Int]]
    /// User IDs of all roster-added participants. Used for participant live-view.
    var participantUserIDs: [String]
    /// Set when the day is ended. Used to compute duration in the Summary tab.
    var endedAt: Date?
}
