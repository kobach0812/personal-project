import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

actor LocalWidgetSyncService: WidgetSyncServicing {
    func storeLatestPlay(_ play: WidgetPayload) async {
        AppGroupStore.save(play)

        #if canImport(WidgetKit)
        await MainActor.run {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
}
