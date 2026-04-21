import SwiftUI

struct CameraView: View {
    @StateObject private var vm = CameraViewModel()
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.accessDenied {
                permissionDeniedView
            } else {
                CameraPreviewView(session: vm.session)
                    .ignoresSafeArea()

                if !vm.isReady {
                    ProgressView()
                        .tint(.white)
                }

                VStack {
                    Spacer()
                    captureButton
                        .padding(.bottom, 48)
                }
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { vm.capturedImage != nil },
                set: { if !$0 { vm.discardCapture() } }
            )
        ) {
            if let image = vm.capturedImage {
                CapturePreviewView(image: image, onDiscard: vm.discardCapture)
                    .environmentObject(env)
            }
        }
        .onAppear { vm.onAppear() }
        .onDisappear { vm.onDisappear() }
    }

    private var captureButton: some View {
        Button(action: vm.capturePhoto) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
            Text("Camera access required")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Enable it in Settings to post plays.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(32)
    }
}
