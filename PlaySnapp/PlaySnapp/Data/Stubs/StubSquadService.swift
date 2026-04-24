import Foundation

actor StubSquadService: SquadServicing {
    private var squads: [Squad] = []
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
        squads.append(squad)
        await sessionStore.setActiveSquad(id: squad.id)
        return squad
    }

    func joinSquad(inviteCode: String) async throws -> Squad {
        let userID = await sessionStore.currentUserID() ?? UUID().uuidString
        let squad = Squad(
            id: "joined-\(inviteCode.lowercased())",
            name: "Tuesday Badminton",
            createdBy: "user-4",
            memberIDs: [userID, "user-4"],
            inviteCode: inviteCode.uppercased(),
            createdAt: .now.addingTimeInterval(-7200)
        )
        if !squads.contains(where: { $0.id == squad.id }) {
            squads.append(squad)
        }
        await sessionStore.setActiveSquad(id: squad.id)
        return squad
    }

    func fetchCurrentSquad() async throws -> Squad? {
        let activeID = await sessionStore.fetchCurrentUser()?.activeSquadID
        return squads.first(where: { $0.id == activeID }) ?? squads.first
    }

    func fetchAllSquads() async throws -> [Squad] {
        squads
    }

    func setActiveSquad(id: String) async throws {
        await sessionStore.setActiveSquad(id: id)
    }
}
