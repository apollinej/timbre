import SwiftUI

struct PlaybackBar: View {
    let memo: Memo
    @Bindable var viewModel: TranscriptViewModel

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)

            HStack(spacing: 10) {
                BubbleButton(icon: "backward.end.fill", size: 34, color: Color(hex: "00A8FF")) {
                    Task { await viewModel.skipBy(memo: memo, delta: -10) }
                }

                BubbleButton(
                    icon: viewModel.isPlaying ? "pause.fill" : "play.fill",
                    size: 40,
                    color: Color(hex: "0088FF")
                ) {
                    Task { await viewModel.togglePlayback(memo: memo) }
                }

                BubbleButton(icon: "forward.end.fill", size: 34, color: Color(hex: "00A8FF")) {
                    Task { await viewModel.skipBy(memo: memo, delta: 10) }
                }

                Text(TimeFormatter.format(viewModel.currentTime))
                    .font(TimbreFont.fontBold(size: 15))
                    .foregroundStyle(Color(hex: "044060"))
                    .frame(width: 58, alignment: .trailing)

                ChromeInset {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Color(hex: "044060")

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "00FF88"), Color(hex: "00D070")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: max(8, geo.size.width * (viewModel.duration > 0
                                        ? viewModel.currentTime / viewModel.duration : 0))
                                )
                                .overlay(
                                    VStack {
                                        Capsule().fill(Color.white.opacity(0.45)).frame(height: 2)
                                        Spacer()
                                    }
                                )
                        }
                        .clipShape(Capsule())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let frac = max(0, min(1, value.location.x / geo.size.width))
                                    viewModel.seek(to: frac * viewModel.duration)
                                }
                        )
                    }
                }
                .frame(height: 16)

                Text(TimeFormatter.format(viewModel.duration))
                    .font(Theme.smallMetaFont)
                    .foregroundStyle(Color(hex: "0088C8"))
                    .frame(width: 58)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(BrushedMetal(baseColor: Color(hex: "A8D8F8"), intensity: 0.34))
        }
    }
}
