import SwiftUI

struct EmptyStateView: View {
    let importer: AudioImporter

    var body: some View {
        VStack(spacing: 16) {
            // Waveform icon as a bubble
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "90B8E0").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "waveform")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Color(hex: "7898B8"))
            }

            Text("import a voice memo")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "5070A0"))

            Text("drag an audio file here or click + to browse")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "8898B0"))

            Text(".m4a  .wav  .mp3  .flac  .aac  .caf  .aiff")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(hex: "A0A8B8"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
