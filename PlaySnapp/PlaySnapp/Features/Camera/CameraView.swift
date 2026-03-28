import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.85), Color.orange.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 48))
                                .foregroundStyle(.white)

                            Text("Camera scaffold ready")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("AVFoundation capture is the next slice. This screen already holds the right place in navigation.")
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(height: 360)

                NavigationLink {
                    CapturePreviewView()
                } label: {
                    Label("Open capture preview", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text(viewModel.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Camera")
        }
    }
}
