import AVFoundation
import Foundation

enum CameraAccessState {
    case unknown
    case granted
    case denied
}

final class CameraManager {
    func currentAccessState() -> CameraAccessState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func requestAccess() async -> CameraAccessState {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .granted : .denied
    }
}
