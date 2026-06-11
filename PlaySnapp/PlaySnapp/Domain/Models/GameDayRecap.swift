import Foundation

/// A derived summary of one finished day of play (or a finished bracket),
/// rendered as the game day recap card (M26). Built locally — never stored.
struct GameDayRecap: Equatable, Sendable {
    let gameTitle: String
    let date: Date
    let playerCount: Int
    let matchCount: Int
    /// Most wins that day; nil for bracket recaps and days where nobody won.
    let topPerformerName: String?
    /// Largest winning margin as "21–9" (winner score first); nil when no match has scores.
    let biggestScoreline: String?
    /// Set only for the bracket-final variant — switches the card to the gold champion treatment.
    let championTeamName: String?
}

extension GameDayRecap: Identifiable {
    /// Stable identity for sheet presentation; recaps are one-per-moment, never listed.
    var id: String { "\(gameTitle)|\(date.timeIntervalSince1970)" }
}
