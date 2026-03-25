import SwiftUI

struct TranscriptionProgressView: View {
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                Text("Transcribing…")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .monospacedDigit()
            }
            .frame(width: 240)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Cancel", role: .cancel) {
                onCancel()
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusText: String {
        if progress < 0.1 {
            return "Loading models…"
        } else if progress < 0.7 {
            return "Transcribing audio…"
        } else if progress < 0.9 {
            return "Identifying speakers…"
        } else {
            return "Merging results…"
        }
    }
}
