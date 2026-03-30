import Foundation

struct DeviceRegistration: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var fcmToken: String
    var platform: String
    var appVersion: String
    var updatedAt: Date
}
