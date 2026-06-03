import Foundation
import Testing
@testable import PlaySnapp

// MARK: - Fixture helpers

private func team(_ id: String) -> FixedTeam {
    FixedTeam(id: id, name: id, playerIDs: ["x", "y"])
}

private func group(_ name: String, teamCount: Int) -> BracketGroup {
    let teams = (1...teamCount).map { team("\(name)\($0)") }
    return BracketGroup(id: "g-\(name)", name: name, teams: teams, matches: [], advanceCount: nil)
}

// MARK: - Tests

struct ConfigureKnockoutServiceTests {

    private func makeBracket(groups: [BracketGroup]) async throws -> (StubBracketTournamentService, BracketTournament) {
        let service = StubBracketTournamentService()
        let bracket = try await service.createBracket(
            in: "t1", squadID: "sq1", createdBy: "host",
            title: "Test", groups: groups
        )
        return (service, bracket)
    }

    @Test("configureKnockout sets advanceCount per group and flips status to knockout")
    func configureKnockout_setsAdvanceCountAndStatus() async throws {
        let groups = [group("A", teamCount: 4), group("B", teamCount: 4)]
        let (service, bracket) = try await makeBracket(groups: groups)

        let result = try await service.configureKnockout(
            bracketID: bracket.id,
            advanceCounts: [groups[0].id: 2, groups[1].id: 2],
            bestOf: 3,
            squadID: "sq1", tournamentID: "t1"
        )

        #expect(result.status == .knockout)
        #expect(result.knockoutBestOf == 3)
        #expect(result.groups.first { $0.id == groups[0].id }?.advanceCount == 2)
        #expect(result.groups.first { $0.id == groups[1].id }?.advanceCount == 2)
    }

    @Test("4 advancing teams start the knockout at the semifinal round")
    func configureKnockout_fourAdvancing_startsAtSemifinal() async throws {
        let groups = [group("A", teamCount: 4), group("B", teamCount: 4)]
        let (service, bracket) = try await makeBracket(groups: groups)

        let result = try await service.configureKnockout(
            bracketID: bracket.id,
            advanceCounts: [groups[0].id: 2, groups[1].id: 2],
            bestOf: 3,
            squadID: "sq1", tournamentID: "t1"
        )

        #expect(result.knockoutMatches.filter { $0.round == .semifinal }.count == 2)
        #expect(result.knockoutMatches.allSatisfy { $0.round == .semifinal })
    }

    @Test("8 advancing teams start the knockout at the quarterfinal round")
    func configureKnockout_eightAdvancing_startsAtQuarterfinal() async throws {
        let groups = [group("A", teamCount: 4), group("B", teamCount: 4)]
        let (service, bracket) = try await makeBracket(groups: groups)

        let result = try await service.configureKnockout(
            bracketID: bracket.id,
            advanceCounts: [groups[0].id: 4, groups[1].id: 4],
            bestOf: 5,
            squadID: "sq1", tournamentID: "t1"
        )

        #expect(result.knockoutMatches.filter { $0.round == .quarterfinal }.count == 4)
        #expect(result.knockoutBestOf == 5)
    }

    @Test("fewer than 2 advancing teams is rejected as unsupported")
    func configureKnockout_tooFewAdvancing_throws() async throws {
        let groups = [group("A", teamCount: 4)]
        let (service, bracket) = try await makeBracket(groups: groups)

        await #expect(throws: BracketTournamentServiceError.unsupportedTeamCount) {
            _ = try await service.configureKnockout(
                bracketID: bracket.id,
                advanceCounts: [groups[0].id: 1],
                bestOf: 3,
                squadID: "sq1", tournamentID: "t1"
            )
        }
    }

    @Test("more than 8 advancing teams is rejected as unsupported")
    func configureKnockout_tooManyAdvancing_throws() async throws {
        let groups = [group("A", teamCount: 4), group("B", teamCount: 4), group("C", teamCount: 4)]
        let (service, bracket) = try await makeBracket(groups: groups)

        await #expect(throws: BracketTournamentServiceError.unsupportedTeamCount) {
            _ = try await service.configureKnockout(
                bracketID: bracket.id,
                advanceCounts: [groups[0].id: 4, groups[1].id: 4, groups[2].id: 4],
                bestOf: 3,
                squadID: "sq1", tournamentID: "t1"
            )
        }
    }
}
