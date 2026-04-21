import Foundation

/// Persists onboarding completion flags locally so that a Firestore write failure
/// cannot put the user into an infinite onboarding loop on the next launch.
/// Flags are keyed per user ID so multi-account devices are handled correctly.
/// This is a positive-only store: a flag set locally can advance state forward
/// but cannot undo a flag that Firestore already recorded.
enum LocalOnboardingFlagStore {
    private static func key(_ flag: Flag, userID: String) -> String {
        "onboarding_\(flag.rawValue)_\(userID)"
    }

    static func set(_ flag: Flag, for userID: String) {
        UserDefaults.standard.set(true, forKey: key(flag, userID: userID))
    }

    static func isSet(_ flag: Flag, for userID: String) -> Bool {
        UserDefaults.standard.bool(forKey: key(flag, userID: userID))
    }
}

extension LocalOnboardingFlagStore {
    enum Flag: String {
        case hasSeenWidgetIntro
    }
}
