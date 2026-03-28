import SwiftUI

struct CapturePreviewView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orange.opacity(0.2))
                .overlay {
                    Text("Captured play preview")
                        .font(.headline)
                }
                .frame(height: 280)

            Text("This view is where post review, caption, and send actions will live once camera capture is wired.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(24)
        .navigationTitle("Preview")
    }
}
