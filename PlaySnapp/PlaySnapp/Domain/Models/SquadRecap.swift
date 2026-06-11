import Foundation

/// A derived summary of the squad's last 7 days, rendered as the weekly recap card (M26).
/// Built locally from already-fetched feed data — never stored.
struct SquadRecap: Equatable, Sendable {
    let squadName: String
    let weekStart: Date
    let weekEnd: Date
    let playCount: Int
    let reactionCount: Int
    /// Member who posted the most plays this week. `reactionSummary` carries no
    /// reactor identity, so "top poster" stands in for the spec's "top reactor".
    let topPosterName: String?
    let topPlay: Play?
}
