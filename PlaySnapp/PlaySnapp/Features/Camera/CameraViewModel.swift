import Combine
import Foundation

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var statusText = "Photo capture and upload belong in Milestone 3."
}
