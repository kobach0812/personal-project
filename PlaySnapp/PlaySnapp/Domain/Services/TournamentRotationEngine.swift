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
        let eligible = session.players.filter { !busyIDs.contains($0.id) && $0.isActive }
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

    // MARK: - Fixed-team round-robin

    /// Fills all empty court slots with fixed-team round-robin matchups.
    /// Picks the matchup played the fewest times (random tiebreak). No team can appear on two courts at once.
    static func generateFixedTeamRound(session: TournamentSession) -> [TournamentMatch] {
        let teams = session.fixedTeams
        guard teams.count >= 2 else { return [] }

        // Build all pair combos
        var allMatchups: [(FixedTeam, FixedTeam)] = []
        for i in 0 ..< teams.count {
            for j in (i + 1) ..< teams.count {
                allMatchups.append((teams[i], teams[j]))
            }
        }

        // Count how many times each matchup has been played
        let playCount = fixedTeamPlayCounts(allMatchups: allMatchups, completedMatches: session.completedMatches)

        // Shuffle for random tiebreak, then stable-sort by play count
        var shuffled = allMatchups.shuffled()
        shuffled.sort { playCount[matchupKey($0.0, $0.1), default: 0] < playCount[matchupKey($1.0, $1.1), default: 0] }

        // Assign to free courts
        let occupiedCourts = Set(session.currentRound.map(\.court))
        var freeCourts = (1 ... session.courts).filter { !occupiedCourts.contains($0) }
        var busyTeamIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        var result: [TournamentMatch] = []

        for (t1, t2) in shuffled {
            guard !freeCourts.isEmpty else { break }
            let allIDs = Set(t1.playerIDs + t2.playerIDs)
            guard allIDs.isDisjoint(with: busyTeamIDs) else { continue }
            let court = freeCourts.removeFirst()
            result.append(TournamentMatch(id: UUID().uuidString, court: court,
                                          teamA: t1.playerIDs, teamB: t2.playerIDs,
                                          winnerTeam: nil))
            busyTeamIDs.formUnion(allIDs)
        }
        return result
    }

    /// Generates the best next fixed-team matchup for a single freed court. Returns nil if no valid matchup.
    static func nextFixedTeamMatch(court: Int, session: TournamentSession) -> TournamentMatch? {
        let teams = session.fixedTeams
        guard teams.count >= 2 else { return nil }

        var allMatchups: [(FixedTeam, FixedTeam)] = []
        for i in 0 ..< teams.count {
            for j in (i + 1) ..< teams.count {
                allMatchups.append((teams[i], teams[j]))
            }
        }

        let playCount = fixedTeamPlayCounts(allMatchups: allMatchups, completedMatches: session.completedMatches)
        var shuffled = allMatchups.shuffled()
        shuffled.sort { playCount[matchupKey($0.0, $0.1), default: 0] < playCount[matchupKey($1.0, $1.1), default: 0] }

        let busyTeamIDs = Set(session.currentRound.flatMap { $0.teamA + $0.teamB })
        for (t1, t2) in shuffled {
            let allIDs = Set(t1.playerIDs + t2.playerIDs)
            if allIDs.isDisjoint(with: busyTeamIDs) {
                return TournamentMatch(id: UUID().uuidString, court: court,
                                      teamA: t1.playerIDs, teamB: t2.playerIDs,
                                      winnerTeam: nil)
            }
        }
        return nil
    }

    // MARK: - Fixed-team helpers

    private static func matchupKey(_ t1: FixedTeam, _ t2: FixedTeam) -> String {
        let ids = [Set(t1.playerIDs), Set(t2.playerIDs)]
            .map { $0.sorted().joined(separator: ",") }
            .sorted()
        return ids.joined(separator: "|")
    }

    private static func fixedTeamPlayCounts(
        allMatchups: [(FixedTeam, FixedTeam)],
        completedMatches: [TournamentMatch]
    ) -> [String: Int] {
        // Build lookup: sorted player-ID set → FixedTeam
        var teamByKey: [String: FixedTeam] = [:]
        for (t1, t2) in allMatchups {
            teamByKey[t1.playerIDs.sorted().joined(separator: ",")] = t1
            teamByKey[t2.playerIDs.sorted().joined(separator: ",")] = t2
        }

        var counts: [String: Int] = [:]
        for match in completedMatches {
            let keyA = match.teamA.sorted().joined(separator: ",")
            let keyB = match.teamB.sorted().joined(separator: ",")
            guard let tA = teamByKey[keyA], let tB = teamByKey[keyB] else { continue }
            counts[matchupKey(tA, tB), default: 0] += 1
        }
        return counts
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
