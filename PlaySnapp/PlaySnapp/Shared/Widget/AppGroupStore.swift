import Foundation

struct WidgetPayload: Codable, Equatable, Sendable {
    let playID: String
    let squadID: String
    let senderName: String
    let sportName: String
    let createdAt: Date
    let thumbnailURL: URL?
}

enum AppGroupStore {
    nonisolated static let suiteName = "group.com.playsnap.shared"
    nonisolated private static let payloadKey = "latest_widget_payload"

    nonisolated static func save(_ payload: WidgetPayload) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return
        }

        let data = try? JSONEncoder().encode(payload)
        defaults.set(data, forKey: payloadKey)
    }

    nonisolated static func load() -> WidgetPayload? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: payloadKey),
            let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
        else {
            return nil
        }

        return payload
    }
}
