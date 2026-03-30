import Foundation

actor StubSquadService: SquadServicing {
    private var currentSquad: Squad?

    func createSquad(name: String, sport: Sport) async throws -> Squad {
        let squad = Squad(
            id: UUID().uuidString,
            name: name,
            sport: sport,
            memberIDs: [AppFixtures.sampleUser.id],
            inviteCode: String(name.prefix(4)).uppercased() + "1",
            createdAt: .now
        )

        currentSquad = squad
        return squad
    }

    func joinSquad(inviteCode: String) async throws -> Squad {
        let squad = Squad(
            id: "joined-squad",
            name: "Local Run Club",
            sport: .running,
            memberIDs: ["user-1", "user-4"],
            inviteCode: inviteCode.uppercased(),
            createdAt: .now.addingTimeInterval(-7200)
        )

        currentSquad = squad
        return squad
    }

    func fetchCurrentSquad() async throws -> Squad? {
        currentSquad ?? AppFixtures.sampleSquad
    }
}
