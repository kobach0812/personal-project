import SwiftUI
import WidgetKit

@main
struct PlaySnapWidget: Widget {
    let kind = "PlaySnapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Latest squad play")
        .description("Keep the newest squad moment on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
