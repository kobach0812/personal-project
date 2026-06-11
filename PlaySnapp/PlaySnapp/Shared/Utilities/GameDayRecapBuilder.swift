import Foundation

/// Pure derivation of the game day recap from a finished session or bracket (M26).
enum GameDayRecapBuilder {

    /// Day-session variant — built when the organizer ends a day.
    static func build(session: GameSession, matches: [GameMatch], now: Date = .now) -> GameDayRecap {
        GameDayRecap(
            gameTitle: session.title,
            date: session.endedAt ?? now,
            playerCount: session.players.count,
            matchCount: matches.count,
            topPerformerName: topPerformer(in: session.players),
            biggestScoreline: biggestScoreline(in: matches),
            championTeamName: nil
        )
    }

    /// Bracket-final variant — built when a knockout final completes.
    static func build(bracket: BracketTournament, champion: FixedTeam, now: Date = .now) -> GameDayRecap {
        let groupMatchCount = bracket.groups
            .flatMap(\.matches)
            .filter { $0.winnerTeamID != nil }
            .count
        let knockoutMatchCount = bracket.knockoutMatches
            .filter { $0.winnerTeamID != nil }
            .count
        let playerIDs = Set(bracket.groups.flatMap(\.teams).flatMap(\.playerIDs))

        return GameDayRecap(
            gameTitle: bracket.title,
            date: now,
            playerCount: playerIDs.count,
            matchCount: groupMatchCount + knockoutMatchCount,
            topPerformerName: nil,
            biggestScoreline: nil,
            championTeamName: champion.name
        )
    }

    // MARK: - Helpers

    private static func topPerformer(in players: [GamePlayer]) -> String? {
        guard players.contains(where: { $0.wins > 0 }) else { return nil }
        return players.min { a, b in
            if a.wins != b.wins { return a.wins > b.wins }
            if a.played != b.played { return a.played > b.played }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }?.name
    }

    private static func biggestScoreline(in matches: [GameMatch]) -> String? {
        let scored = matches.compactMap { match -> (high: Int, low: Int)? in
            guard let a = match.teamAScore, let b = match.teamBScore else { return nil }
            return (max(a, b), min(a, b))
        }
        guard let best = scored.max(by: { lhs, rhs in
            let (ml, mr) = (lhs.high - lhs.low, rhs.high - rhs.low)
            if ml != mr { return ml < mr }
            return lhs.high < rhs.high
        }) else { return nil }
        return "\(best.high)–\(best.low)"
    }
}
