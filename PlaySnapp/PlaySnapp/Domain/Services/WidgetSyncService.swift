import Foundation

protocol WidgetSyncServicing {
    func storeLatestPlay(_ play: WidgetPayload) async
}
