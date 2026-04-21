import Foundation

protocol UserProfileServicing {
    func fetchCurrentUser() async throws -> AppUser?
    /// Updates the user's display name and primary sport. Used by the profile edit flow.
    func updateProfile(name: String, sport: Sport) async throws -> AppUser
    /// Persists an avatar URL that was already uploaded via StorageServicing.
    func updateAvatar(url: URL) async throws -> AppUser
}
