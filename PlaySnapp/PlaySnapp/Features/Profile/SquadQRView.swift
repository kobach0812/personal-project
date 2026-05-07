import SwiftUI

struct SquadQRView: View {
    let squad: Squad
    @Environment(\.dismiss) private var dismiss

    private var squadURL: String { "playsnapp://join?code=\(squad.inviteCode)" }
    private var qrImage: UIImage? { QRCodeGenerator.image(for: squadURL, size: 300) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                } else {
                    ContentUnavailableView("Could not generate QR code", systemImage: "qrcode")
                }

                VStack(spacing: 4) {
                    Text(squad.name)
                        .font(.title2.weight(.semibold))
                    Text("Scan to join this squad")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let qrImage {
                    ShareLink(
                        item: Image(uiImage: qrImage),
                        preview: SharePreview("Join \(squad.name) on PlaySnapp", image: Image(uiImage: qrImage))
                    ) {
                        Label("Share QR Code", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Squad QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
