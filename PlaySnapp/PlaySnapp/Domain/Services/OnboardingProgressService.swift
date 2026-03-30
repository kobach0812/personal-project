import Foundation

protocol OnboardingProgressServicing {
    func completeProfile(name: String, sport: Sport) async throws -> AppSession
    func markJoinedSquad() async throws -> AppSession
    func markSeenWidgetIntro() async throws -> AppSession
}
