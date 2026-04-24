import Foundation

protocol UserProfileServicing {
    func fetchCurrentUser() async throws -> AppUser?
    /// Fetches multiple user profiles by ID in parallel. Used for roster display.
    func fetchUsers(ids: [String]) async throws -> [AppUser]
    /// Updates the user's display name. Used by the profile edit flow.
    func updateProfile(name: String) async throws -> AppUser
    /// Persists an avatar URL that was already uploaded via StorageServicing.
    func updateAvatar(url: URL) async throws -> AppUser
}
