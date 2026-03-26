import SwiftUI

struct EmptyStateView: View {
    let importer: AudioImporter

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "00FFFF").opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 12,
                                endRadius: 56
                            )
                        )
                        .frame(width: 112, height: 112)

                    Image(systemName: "waveform")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00D8FF"), Color(hex: "0080FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("import a voice memo")
                    .font(TimbreFont.fontBold(size: 22))
                    .foregroundStyle(Color(hex: "044060"))

                Text("drag an audio file here or click + to browse")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color(hex: "0088C8"))

                Text(".m4a  .wav  .mp3  .flac  .aac  .caf  .aiff")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color(hex: "20B0E0"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack {
                    PixelStar(color: Color(hex: "00FF88"))
                    Spacer()
                    PixelStar(color: Color(hex: "00C8FF"))
                }
                Spacer()
                HStack {
                    Spacer()
                    ChromeCornerGrip()
                }
            }
            .padding(12)
            .allowsHitTesting(false)
        }
    }
}
