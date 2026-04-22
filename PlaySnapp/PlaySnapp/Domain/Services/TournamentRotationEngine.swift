import Foundation

enum TournamentRotationEngine {

    // MARK: - Per-match scheduling

    /// Build a new match for a specific court, picking 4 players using rest priority.
    /// Excludes players currently assigned to other (in-progress) matches.
    /// Returns nil if fewer than 4 eligible players are available.
    static func generateMatchForCourt(
        court: Int,
        session: TournamentSession
    ) -> TournamentMatch? {
        let busyIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        let eligible = session.players.filter { !busyIDs.contains($0.id) }
        let sorted = sortedByPriority(eligible)
        guard sorted.count >= 4 else { return nil }
        let four = Array(sorted.prefix(4))
        let (teamA, teamB) = bestPairing(four: four, partnerships: session.partnerships)
        return TournamentMatch(
            id: UUID().uuidString,
            court: court,
            teamA: teamA.map(\.id),
            teamB: teamB.map(\.id),
            winnerTeam: nil
        )
    }

    /// Fill all empty court slots up to `session.courts` with fresh matches.
    /// Used at session start and any time the round is empty.
    static func fillAllCourts(session: TournamentSession) -> [TournamentMatch] {
        var working = session
        var matches = working.currentRound
        let occupied = Set(matches.map { $0.court })
        for court in 1...session.courts where !occupied.contains(court) {
            guard let match = generateMatchForCourt(court: court, session: working) else { break }
            matches.append(match)
            working.currentRound = matches
        }
        return matches
    }

    // MARK: - Post-match updates

    /// Applies match stats (played/wins/losses) AND stamps lastPlayedAt with the new counter.
    static func applyResult(
        players: [TournamentPlayer],
        match: TournamentMatch,
        winner: WinnerTeam,
        matchCounter: Int
    ) -> [TournamentPlayer] {
        let winnerIDs = winner == .teamA ? match.teamA : match.teamB
        let loserIDs  = winner == .teamA ? match.teamB : match.teamA
        var updated = players
        for id in winnerIDs + loserIDs {
            guard let idx = updated.firstIndex(where: { $0.id == id }) else { continue }
            updated[idx].played += 1
            updated[idx].lastPlayedAt = matchCounter
            if winnerIDs.contains(id) { updated[idx].wins += 1 }
            else { updated[idx].losses += 1 }
        }
        return updated
    }

    /// Records that the two teams played together so future rounds avoid repeat partnerships.
    static func updatePartnerships(
        _ partnerships: [String: [String: Int]],
        match: TournamentMatch
    ) -> [String: [String: Int]] {
        var result = partnerships
        for team in [match.teamA, match.teamB] {
            guard team.count == 2 else { continue }
            let a = team[0], b = team[1]
            result[a, default: [:]][b, default: 0] += 1
            result[b, default: [:]][a, default: 0] += 1
        }
        return result
    }

    // MARK: - Private

    /// Priority order for picking who plays next:
    /// 1. Fewest games played (never-played = 0 goes first)
    /// 2. Longest rested (smallest lastPlayedAt)
    /// 3. Random tiebreak (deterministic per-call via explicit key)
    private static func sortedByPriority(_ players: [TournamentPlayer]) -> [TournamentPlayer] {
        let keyed = players.map { ($0, UInt64.random(in: 0...UInt64.max)) }
        let sorted = keyed.sorted { lhs, rhs in
            if lhs.0.played != rhs.0.played { return lhs.0.played < rhs.0.played }
            if lhs.0.lastPlayedAt != rhs.0.lastPlayedAt { return lhs.0.lastPlayedAt < rhs.0.lastPlayedAt }
            return lhs.1 < rhs.1
        }
        return sorted.map(\.0)
    }

    /// Given 4 players, return the team split that minimizes total partnership count.
    /// Three possible splits: (AB vs CD), (AC vs BD), (AD vs BC). Ties broken randomly.
    private static func bestPairing(
        four: [TournamentPlayer],
        partnerships: [String: [String: Int]]
    ) -> ([TournamentPlayer], [TournamentPlayer]) {
        let a = four[0], b = four[1], c = four[2], d = four[3]

        func pairCount(_ x: TournamentPlayer, _ y: TournamentPlayer) -> Int {
            partnerships[x.id]?[y.id] ?? 0
        }

        let splits: [(teamA: [TournamentPlayer], teamB: [TournamentPlayer], score: Int)] = [
            ([a, b], [c, d], pairCount(a, b) + pairCount(c, d)),
            ([a, c], [b, d], pairCount(a, c) + pairCount(b, d)),
            ([a, d], [b, c], pairCount(a, d) + pairCount(b, c))
        ]

        let minScore = splits.map(\.score).min() ?? 0
        let tied = splits.filter { $0.score == minScore }
        let chosen = tied.randomElement()!
        return (chosen.teamA, chosen.teamB)
    }
}
