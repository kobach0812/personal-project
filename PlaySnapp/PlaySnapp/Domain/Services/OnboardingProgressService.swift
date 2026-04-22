import Foundation

protocol OnboardingProgressServicing {
    func completeProfile(name: String) async throws -> AppSession
    func markJoinedSquad() async throws -> AppSession
    func markSeenWidgetIntro() async throws -> AppSession
}
