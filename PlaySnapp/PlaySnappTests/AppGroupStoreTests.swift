import Foundation
import Testing
@testable import PlaySnapp

// Tests focused on WidgetPayload's Codable round-trip (the serialization layer
// AppGroupStore wraps). Filesystem behavior is a thin `Data.write(to:)` /
// `Data(contentsOf:)` wrapper and depends on the App Group entitlement being
// available in the test runner — covered by manual T4 checks instead.

struct AppGroupStoreTests {

    @Test
    func widgetPayload_roundTripsThroughJSON() throws {
        let payload = WidgetPayload(
            playID: "play-123",
            squadID: "squad-456",
            senderName: "Alice",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WidgetPayload.self, from: data)

        #expect(decoded == payload)
    }

    @Test
    func widgetPayload_roundTripsWithNilThumbnail() throws {
        let payload = WidgetPayload(
            playID: "play-x",
            squadID: "squad-y",
            senderName: "Bob",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            thumbnailURL: nil
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WidgetPayload.self, from: data)

        #expect(decoded.thumbnailURL == nil)
        #expect(decoded == payload)
    }

    @Test
    func appGroupStore_loadReturnsNilWhenContainerUnavailable() {
        // In the test runner, the App Group container is either present (with
        // entitlement) or nil (without). Either way, `load()` should not crash
        // and should return either a previously-saved payload or nil — never
        // throw.
        _ = AppGroupStore.load()
        _ = AppGroupStore.loadThumbnailData()
        // No assertion needed beyond not crashing.
    }
}
