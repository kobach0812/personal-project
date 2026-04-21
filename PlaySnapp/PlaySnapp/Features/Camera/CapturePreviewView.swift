import SwiftUI

struct CapturePreviewView: View {
    let image: UIImage
    let onDiscard: () -> Void

    @EnvironmentObject private var env: AppEnvironment
    @State private var caption = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Add a caption...", text: $caption)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("New Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { onDiscard() }
                        .disabled(isPosting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPosting {
                        ProgressView()
                    } else {
                        Button("Post") { Task { await post() } }
                    }
                }
            }
        }
    }

    private func post() async {
        isPosting = true
        errorMessage = nil
        defer { isPosting = false }

        do {
            guard let squad = try await env.squadService.fetchCurrentSquad() else {
                errorMessage = "You are not in a squad."
                return
            }
            let raw = image.jpegData(compressionQuality: 1.0) ?? Data()
            let compressed = ImageCompressor.jpegData(from: raw) ?? raw
            let url = try await env.storageService.uploadPhoto(data: compressed, squadID: squad.id)
            _ = try await env.playService.postPlay(
                mediaURL: url,
                storagePath: nil,
                mediaType: .photo,
                caption: caption.isEmpty ? nil : caption
            )
            onDiscard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
