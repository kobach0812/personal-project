import Foundation
import WidgetKit

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, payload: samplePayload)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, payload: AppGroupStore.load() ?? samplePayload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = WidgetEntry(date: .now, payload: AppGroupStore.load() ?? samplePayload)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var samplePayload: WidgetPayload {
        WidgetPayload(
            playID: "sample-play",
            squadID: "sample-squad",
            senderName: "Maya",
            createdAt: .now,
            thumbnailURL: nil
        )
    }
}
