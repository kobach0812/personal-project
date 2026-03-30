import Foundation

protocol UserProfileServicing {
    func fetchCurrentUser() async throws -> AppUser?
}
