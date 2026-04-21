import Foundation
import os.log

private let appGroupLog = Logger(subsystem: "com.andythang.PlaySnapp", category: "AppGroup")

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
    nonisolated private static let thumbnailFilename = "latest_thumbnail.jpg"

    nonisolated static func saveThumbnail(_ data: Data) {
        guard let fileURL = containerFileURL(named: thumbnailFilename) else {
            appGroupLog.error("saveThumbnail failed: containerURL nil")
            return
        }
        do {
            try data.write(to: fileURL, options: .atomic)
            appGroupLog.info("thumbnail saved bytes=\(data.count)")
        } catch {
            appGroupLog.error("saveThumbnail failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func loadThumbnailData() -> Data? {
        guard let fileURL = containerFileURL(named: thumbnailFilename) else { return nil }
        return try? Data(contentsOf: fileURL)
    }

    nonisolated static func save(_ payload: WidgetPayload) {
        guard let fileURL = containerFileURL(named: payloadFilename) else {
            appGroupLog.error("save failed: containerURL nil for suite \(suiteName, privacy: .public) — App Group not provisioned")
            return
        }
        do {
            let data = try JSONEncoder().encode(payload)
            try data.write(to: fileURL, options: .atomic)
            appGroupLog.info("save ok at \(fileURL.path, privacy: .public) bytes=\(data.count)")
        } catch {
            appGroupLog.error("save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func load() -> WidgetPayload? {
        guard let fileURL = containerFileURL(named: payloadFilename) else {
            appGroupLog.error("load failed: containerURL nil for suite \(suiteName, privacy: .public)")
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            appGroupLog.info("load: no file yet at \(fileURL.path, privacy: .public)")
            return nil
        }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }

    nonisolated private static func containerFileURL(named filename: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(filename)
    }
}
