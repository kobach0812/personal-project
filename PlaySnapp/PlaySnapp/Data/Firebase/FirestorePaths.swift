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
}
