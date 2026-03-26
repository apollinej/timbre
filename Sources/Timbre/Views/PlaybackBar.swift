import SwiftUI

struct PlaybackBar: View {
    @Bindable var viewModel: TranscriptViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Top bevel
            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)

            HStack(spacing: 6) {
                // Transport bubble buttons
                BubbleButton(icon: "backward.end.fill", size: 28, color: Color(hex: "7098C0")) {
                    viewModel.seek(to: max(0, viewModel.currentTime - 10))
                }

                BubbleButton(
                    icon: viewModel.isPlaying ? "pause.fill" : "play.fill",
                    size: 34,
                    color: Color(hex: "5888D0")
                ) {
                    viewModel.togglePlayback()
                }

                BubbleButton(icon: "forward.end.fill", size: 28, color: Color(hex: "7098C0")) {
                    viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 10))
                }

                // Time display
                Text(TimeFormatter.format(viewModel.currentTime))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "3868A0"))
                    .frame(width: 50, alignment: .trailing)

                // Seek bar — chrome inset
                ChromeInset {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Color(hex: "2A4060")

                            // Green progress (like classic QuickTime!)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "60C060"), Color(hex: "40A840")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: geo.size.width * (viewModel.duration > 0
                                        ? viewModel.currentTime / viewModel.duration : 0)
                                )
                                .overlay(
                                    VStack {
                                        Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                                        Spacer()
                                    }
                                )
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let frac = max(0, min(1, value.location.x / geo.size.width))
                                    viewModel.seek(to: frac * viewModel.duration)
                                }
                        )
                    }
                }
                .frame(height: 10)

                Text(TimeFormatter.format(viewModel.duration))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "7898B0"))
                    .frame(width: 50)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BrushedMetal(baseColor: Color(hex: "B8BCC8"), intensity: 0.3))
        }
    }
}
