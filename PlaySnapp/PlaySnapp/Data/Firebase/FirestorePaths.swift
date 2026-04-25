import Foundation

enum FirestorePaths {
    static func user(_ userID: String) -> String {
        "users/\(userID)"
    }

    static func userDevices(_ userID: String) -> String {
        "\(user(userID))/devices"
    }

    static func squad(_ squadID: String) -> String {
        "squads/\(squadID)"
    }

    static func squadMembers(_ squadID: String) -> String {
        "\(squad(squadID))/members"
    }

    static func squadPlays(_ squadID: String) -> String {
        "\(squad(squadID))/plays"
    }

    static func play(_ squadID: String, _ playID: String) -> String {
        "\(squadPlays(squadID))/\(playID)"
    }

    static func playReactions(squadID: String, playID: String) -> String {
        "\(squadPlays(squadID))/\(playID)/reactions"
    }

    static func invite(_ inviteCode: String) -> String {
        "invites/\(inviteCode)"
    }

    static func userNotifications(_ userID: String) -> String {
        "\(user(userID))/notifications"
    }

    static func userNotification(_ notificationID: String, userID: String) -> String {
        "\(userNotifications(userID))/\(notificationID)"
    }

    static func friends(_ userID: String) -> String {
        "\(user(userID))/friends"
    }

    static func friend(_ userID: String, _ friendID: String) -> String {
        "\(friends(userID))/\(friendID)"
    }

    static func friendRequest(_ requestID: String) -> String {
        "friendRequests/\(requestID)"
    }

    static func tournaments(_ squadID: String) -> String {
        "\(squad(squadID))/tournaments"
    }

    static func tournament(_ squadID: String, _ tournamentID: String) -> String {
        "\(tournaments(squadID))/\(tournamentID)"
    }

    // MARK: Day sessions within a tournament

    static func tournamentSessions(_ squadID: String, _ tournamentID: String) -> String {
        "\(tournament(squadID, tournamentID))/sessions"
    }

    static func tournamentSession(_ squadID: String, _ tournamentID: String, _ sessionID: String) -> String {
        "\(tournamentSessions(squadID, tournamentID))/\(sessionID)"
    }

    // MARK: Matches within a day session

    static func sessionMatches(_ squadID: String, _ tournamentID: String, _ sessionID: String) -> String {
        "\(tournamentSession(squadID, tournamentID, sessionID))/matches"
    }

    static func sessionMatch(_ squadID: String, _ tournamentID: String, _ sessionID: String, _ matchID: String) -> String {
        "\(sessionMatches(squadID, tournamentID, sessionID))/\(matchID)"
    }

    static func leaderboard(_ squadID: String) -> String {
        "\(squad(squadID))/leaderboard"
    }

    static func leaderboardEntry(_ squadID: String, _ playerID: String) -> String {
        "\(leaderboard(squadID))/\(playerID)"
    }
}
