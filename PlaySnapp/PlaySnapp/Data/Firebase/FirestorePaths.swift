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

    static func games(_ squadID: String) -> String {
        "\(squad(squadID))/games"
    }

    static func game(_ squadID: String, _ gameID: String) -> String {
        "\(games(squadID))/\(gameID)"
    }

    // MARK: Day sessions within a game

    static func gameSessions(_ squadID: String, _ gameID: String) -> String {
        "\(game(squadID, gameID))/sessions"
    }

    static func gameSession(_ squadID: String, _ gameID: String, _ sessionID: String) -> String {
        "\(gameSessions(squadID, gameID))/\(sessionID)"
    }

    // MARK: Matches within a day session

    static func sessionMatches(_ squadID: String, _ gameID: String, _ sessionID: String) -> String {
        "\(gameSession(squadID, gameID, sessionID))/matches"
    }

    static func sessionMatch(_ squadID: String, _ gameID: String, _ sessionID: String, _ matchID: String) -> String {
        "\(sessionMatches(squadID, gameID, sessionID))/\(matchID)"
    }

    // MARK: Registrations within a day session

    static func registrations(_ squadID: String, _ gameID: String, _ sessionID: String) -> String {
        "\(gameSession(squadID, gameID, sessionID))/registrations"
    }

    static func registration(_ squadID: String, _ gameID: String, _ sessionID: String, _ userID: String) -> String {
        "\(registrations(squadID, gameID, sessionID))/\(userID)"
    }

    // MARK: Bracket games within a parent game

    static func brackets(_ squadID: String, _ gameID: String) -> String {
        "\(game(squadID, gameID))/brackets"
    }

    static func bracket(_ squadID: String, _ gameID: String, _ bracketID: String) -> String {
        "\(brackets(squadID, gameID))/\(bracketID)"
    }

    static func leaderboard(_ squadID: String) -> String {
        "\(squad(squadID))/leaderboard"
    }

    static func leaderboardEntry(_ squadID: String, _ playerID: String) -> String {
        "\(leaderboard(squadID))/\(playerID)"
    }
}
