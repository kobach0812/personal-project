@preconcurrency import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    @Published private(set) var isReady = false
    @Published private(set) var accessDenied = false
    @Published var capturedImage: UIImage?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.playsnapp.camera", qos: .userInitiated)
    private var captureDelegate: PhotoCaptureDelegate?

    func onAppear() {
        Task { await checkPermissionAndSetup() }
    }

    func onDisappear() {
        let session = self.session
        sessionQueue.async { session.stopRunning() }
    }

    func capturePhoto() {
        let output = self.photoOutput
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate { [weak self] image in
            Task { @MainActor [weak self] in
                self?.capturedImage = image
                self?.captureDelegate = nil
            }
        }
        captureDelegate = delegate
        sessionQueue.async { output.capturePhoto(with: settings, delegate: delegate) }
    }

    func discardCapture() {
        capturedImage = nil
    }

    private func checkPermissionAndSetup() async {
        let manager = CameraManager()
        var access = manager.currentAccessState()
        if access == .unknown {
            access = await manager.requestAccess()
        }
        if access == .granted {
            configureSession()
        } else {
            accessDenied = true
        }
    }

    private func configureSession() {
        let session = self.session
        let output = self.photoOutput
        sessionQueue.async {
            session.beginConfiguration()
            session.sessionPreset = .photo

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
            session.startRunning()

            DispatchQueue.main.async { [weak self] in
                self?.isReady = true
            }
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            completion(nil)
            return
        }
        completion(UIImage(data: data))
    }
}
