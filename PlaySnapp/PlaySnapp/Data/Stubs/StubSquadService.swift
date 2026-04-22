import Foundation

actor StubSquadService: SquadServicing {
    private var currentSquad: Squad?
    private let sessionStore: StubSessionStore

    init(sessionStore: StubSessionStore = StubSessionStore()) {
        self.sessionStore = sessionStore
    }

    func createSquad(name: String) async throws -> Squad {
        let userID = await sessionStore.currentUserID() ?? UUID().uuidString
        let squad = Squad(
            id: UUID().uuidString,
            name: name,
            createdBy: userID,
            memberIDs: [userID],
            inviteCode: String(name.prefix(4)).uppercased() + "1",
            createdAt: .now
        )

        currentSquad = squad
        await sessionStore.setCurrentSquad(id: squad.id)
        return squad
    }

    func joinSquad(inviteCode: String) async throws -> Squad {
        let userID = await sessionStore.currentUserID() ?? UUID().uuidString
        let squad = Squad(
            id: "joined-squad",
            name: "Tuesday Badminton",
            createdBy: "user-4",
            memberIDs: [userID, "user-4"],
            inviteCode: inviteCode.uppercased(),
            createdAt: .now.addingTimeInterval(-7200)
        )

        currentSquad = squad
        await sessionStore.setCurrentSquad(id: squad.id)
        return squad
    }

    func fetchCurrentSquad() async throws -> Squad? {
        currentSquad
    }
}
