import Foundation

struct AppSession: Equatable, Sendable {
    let userID: String
    var hasCompletedProfile: Bool
    var hasJoinedSquad: Bool
    var hasSeenWidgetIntro: Bool
}
