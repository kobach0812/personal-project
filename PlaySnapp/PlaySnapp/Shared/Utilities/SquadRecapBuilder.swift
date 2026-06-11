import Foundation

/// Pure derivation of the weekly recap from already-fetched feed data (M26).
enum SquadRecapBuilder {
    private static let windowSeconds: TimeInterval = 7 * 86_400

    static func build(plays: [Play], squad: Squad, now: Date = .now) -> SquadRecap {
        let weekStart = now.addingTimeInterval(-windowSeconds)
        let window = plays.filter { $0.createdAt >= weekStart && $0.createdAt <= now }

        let reactionCount = window.reduce(0) { $0 + $1.reactionSummary.values.reduce(0, +) }

        let topPlay = window.max { a, b in
            let (ra, rb) = (a.reactionSummary.values.reduce(0, +), b.reactionSummary.values.reduce(0, +))
            if ra != rb { return ra < rb }
            return a.createdAt < b.createdAt
        }

        let postCounts = Dictionary(grouping: window, by: \.senderName).mapValues(\.count)
        let topPoster = postCounts.min { a, b in
            if a.value != b.value { return a.value > b.value }
            return a.key.localizedCaseInsensitiveCompare(b.key) == .orderedAscending
        }?.key

        return SquadRecap(
            squadName: squad.name,
            weekStart: weekStart,
            weekEnd: now,
            playCount: window.count,
            reactionCount: reactionCount,
            topPosterName: topPoster,
            topPlay: topPlay
        )
    }
}
