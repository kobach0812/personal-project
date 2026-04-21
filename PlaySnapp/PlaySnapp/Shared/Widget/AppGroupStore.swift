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
    nonisolated static let suiteName = "group.com.playsnapp.shared"
    nonisolated private static let payloadFilename = "latest_widget_payload.json"

    nonisolated static func save(_ payload: WidgetPayload) {
        guard let fileURL = containerFileURL() else { return }
        let data = try? JSONEncoder().encode(payload)
        try? data?.write(to: fileURL, options: .atomic)
    }

    nonisolated static func load() -> WidgetPayload? {
        guard let fileURL = containerFileURL(),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }

    nonisolated private static func containerFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(payloadFilename)
    }
}
