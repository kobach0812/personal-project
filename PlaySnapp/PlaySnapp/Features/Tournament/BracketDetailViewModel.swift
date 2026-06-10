import Combine
import SwiftUI

@MainActor
final class BracketDetailViewModel: ObservableObject {
    @Published var bracket: BracketTournament?
    @Published var errorMessage: String?

    private var observerTask: Task<Void, Never>?
    private var bracketService: BracketTournamentServicing?
    private var currentUser: AppUser?

    var isOrganizer: Bool {
        guard let bracket, let user = currentUser else { return false }
        return bracket.createdBy == user.id
    }

    /// Total completed group matches across all groups.
    var groupMatchesPlayed: Int {
        guard let bracket else { return 0 }
        return bracket.groups.reduce(0) { acc, g in
            acc + g.matches.filter { $0.winnerTeamID != nil }.count
        }
    }

    var groupMatchesTotal: Int {
        guard let bracket else { return 0 }
        return bracket.groups.reduce(0) { $0 + $1.matches.count }
    }

    var groupStageComplete: Bool {
        guard let bracket else { return false }
        return BracketEngine.groupStageComplete(bracket)
    }

    /// True once the knockout phase has been generated (status advanced past the group stage).
    var knockoutConfigured: Bool {
        guard let bracket else { return false }
        return bracket.status == .knockout || bracket.status == .finished
    }

    /// Recomputed on every call — standings calc is cheap and the bracket changes only via observer.
    func groupStandings(for group: BracketGroup) -> [FixedTeam] {
        let order = BracketEngine.standings(for: group)
        var byID = Dictionary(uniqueKeysWithValues: group.teams.map { ($0.id, $0) })
        return order.compactMap { byID.removeValue(forKey: $0) }
    }

    func teamName(_ id: String, in group: BracketGroup) -> String {
        group.teams.first { $0.id == id }?.name ?? id
    }

    /// A team's record for the bento leader tile.
    struct TeamRecord: Equatable {
        let team: FixedTeam
        let wins: Int
        let losses: Int
        let diff: Int
    }

    /// Best team across all groups (wins, then point diff). `nil` until at least one
    /// group match has been played — the leader tile shows a placeholder until then.
    var overallLeader: TeamRecord? {
        guard let bracket else { return nil }
        let records = bracket.groups.flatMap { group in
            group.teams.map { team in
                TeamRecord(team: team,
                           wins: wins(team.id, in: group),
                           losses: losses(team.id, in: group),
                           diff: pointDiff(team.id, in: group))
            }
        }
        guard records.contains(where: { $0.wins > 0 || $0.losses > 0 }) else { return nil }
        return records.max { a, b in
            a.wins != b.wins ? a.wins < b.wins : a.diff < b.diff
        }
    }

    func wins(_ teamID: String, in group: BracketGroup) -> Int {
        group.matches.filter { $0.winnerTeamID == teamID }.count
    }

    func losses(_ teamID: String, in group: BracketGroup) -> Int {
        group.matches.filter { m in
            m.winnerTeamID != nil
                && m.winnerTeamID != teamID
                && (m.teamAID == teamID || m.teamBID == teamID)
        }.count
    }

    func pointDiff(_ teamID: String, in group: BracketGroup) -> Int {
        group.matches.reduce(0) { acc, m in
            guard m.completedAt != nil, let a = m.scoreA, let b = m.scoreB else { return acc }
            if m.teamAID == teamID { return acc + (a - b) }
            if m.teamBID == teamID { return acc + (b - a) }
            return acc
        }
    }

    // MARK: - Loading

    func start(
        bracket: BracketTournament,
        currentUser: AppUser?,
        service: BracketTournamentServicing
    ) {
        self.bracket = bracket
        self.currentUser = currentUser
        self.bracketService = service
        startObserving(bracket: bracket, service: service)
    }

    private func startObserving(bracket: BracketTournament, service: BracketTournamentServicing) {
        observerTask?.cancel()
        observerTask = Task {
            let stream = service.observeBracket(
                bracketID: bracket.id,
                squadID: bracket.squadID,
                tournamentID: bracket.parentTournamentID
            )
            for await fresh in stream {
                guard !Task.isCancelled else { break }
                self.bracket = fresh
            }
        }
    }

    func cancel() {
        observerTask?.cancel()
        observerTask = nil
    }

    deinit {
        observerTask?.cancel()
    }

    // MARK: - Writes

    func recordResult(groupID: String, matchID: String, scoreA: Int, scoreB: Int) async {
        guard let bracket, let service = bracketService else { return }
        do {
            _ = try await service.recordGroupMatchResult(
                bracketID: bracket.id,
                groupID: groupID,
                matchID: matchID,
                scoreA: scoreA,
                scoreB: scoreB,
                squadID: bracket.squadID,
                tournamentID: bracket.parentTournamentID
            )
            // Live state will arrive via observeBracket; no local mutation needed.
        } catch {
            errorMessage = "Could not save score."
        }
    }

    // MARK: - Knockout reads

    var knockoutBestOf: Int { bracket?.knockoutBestOf ?? 0 }

    /// Sets a team must win to take a knockout match in the configured best-of-N.
    var setsToWin: Int { BracketEngine.setsToWin(bestOf: max(1, knockoutBestOf)) }

    /// Knockout matches in a round, ordered by bracket position.
    func knockoutMatches(in round: KnockoutRound) -> [KnockoutMatch] {
        (bracket?.knockoutMatches ?? [])
            .filter { $0.round == round }
            .sorted { $0.position < $1.position }
    }

    /// Looks up a team's display name anywhere in the bracket's groups.
    func teamName(_ id: String?) -> String {
        guard let id else { return "—" }
        for group in bracket?.groups ?? [] {
            if let team = group.teams.first(where: { $0.id == id }) { return team.name }
        }
        return id
    }

    /// Seed label = group letter + standing rank, e.g. "A1" for the top team of group A.
    func seedLabel(for id: String?) -> String? {
        guard let id else { return nil }
        return seedLabels[id]
    }

    private var seedLabels: [String: String] {
        var map: [String: String] = [:]
        for group in bracket?.groups ?? [] {
            for (index, teamID) in BracketEngine.standings(for: group).enumerated() {
                map[teamID] = "\(group.name)\(index + 1)"
            }
        }
        return map
    }

    /// The final winner, present only once the bracket is finished.
    var champion: FixedTeam? {
        guard let bracket, bracket.status == .finished,
              let finalMatch = bracket.knockoutMatches.first(where: { $0.round == .final }),
              let winnerID = finalMatch.winnerTeamID
        else { return nil }
        for group in bracket.groups {
            if let team = group.teams.first(where: { $0.id == winnerID }) { return team }
        }
        return nil
    }

    // MARK: - Knockout writes

    func recordKnockoutSet(matchID: String, set: SetScore) async {
        guard let bracket, let service = bracketService else { return }
        do {
            _ = try await service.recordKnockoutSet(
                bracketID: bracket.id,
                matchID: matchID,
                set: set,
                squadID: bracket.squadID,
                tournamentID: bracket.parentTournamentID
            )
            // Live state will arrive via observeBracket; no local mutation needed.
        } catch {
            errorMessage = "Could not save the set."
        }
    }

    func configureKnockout(advanceCounts: [String: Int], bestOf: Int) async {
        guard let bracket, let service = bracketService else { return }
        do {
            _ = try await service.configureKnockout(
                bracketID: bracket.id,
                advanceCounts: advanceCounts,
                bestOf: bestOf,
                squadID: bracket.squadID,
                tournamentID: bracket.parentTournamentID
            )
            // Live state will arrive via observeBracket; no local mutation needed.
        } catch BracketTournamentServiceError.unsupportedTeamCount {
            errorMessage = "The number of advancing teams must be between 2 and 8."
        } catch {
            errorMessage = "Could not configure the knockout stage."
        }
    }
}
