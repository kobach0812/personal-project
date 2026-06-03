import Foundation

enum BracketTournamentServiceError: Error, Equatable {
    case bracketNotFound
    case unsupportedTeamCount
    case knockoutNotConfigured
}

protocol BracketTournamentServicing: Sendable {

    /// Creates a bracket in `.groupStage`. Round-robin matches are generated per group.
    func createBracket(
        in tournamentID: String,
        squadID: String,
        createdBy: String,
        title: String,
        groups: [BracketGroup]
    ) async throws -> BracketTournament

    func fetchBrackets(in tournamentID: String, squadID: String) async throws -> [BracketTournament]

    /// Records a single-set score for a group match and stamps the winner.
    func recordGroupMatchResult(
        bracketID: String,
        groupID: String,
        matchID: String,
        scoreA: Int,
        scoreB: Int,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament

    /// Picks the top N teams per group, randomly pairs them into the first knockout round
    /// (with byes for odd counts), and persists `knockoutBestOf` + `knockoutMatches`.
    /// Transitions status to `.knockout`.
    func configureKnockout(
        bracketID: String,
        advanceCounts: [String: Int],
        bestOf: Int,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament

    /// Appends one set to a knockout match. If a team reaches the win threshold, stamps the
    /// match winner and auto-generates the next round (or 3rd place / final) as appropriate.
    func recordKnockoutSet(
        bracketID: String,
        matchID: String,
        set: SetScore,
        squadID: String,
        tournamentID: String
    ) async throws -> BracketTournament

    /// Real-time observer for a single bracket document.
    func observeBracket(bracketID: String, squadID: String, tournamentID: String) -> AsyncStream<BracketTournament>
}
