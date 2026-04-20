import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = RecordViewModel()
    let onGoHome: () -> Void
    let onAnalyze: (Memo) -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                headerBanner
                Spacer()
                controlRow
                Spacer().frame(height: 16)
                timerDisplay
                Spacer()
                liveWaveform
            }
        }
        .sheet(isPresented: $vm.showSavePopup, onDismiss: {
            if vm.pendingPostSave {
                vm.pendingPostSave = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    vm.showPostSavePrompt = true
                }
            }
        }) {
            RecordSavePopup(vm: vm, modelContext: modelContext)
        }
        .sheet(isPresented: $vm.showPostSavePrompt) {
            RecordPostSavePrompt(
                onAnalyze: {
                    if let memo = vm.savedMemo {
                        vm.dismissPostSave()
                        onAnalyze(memo)
                    }
                },
                onRecordAnother: { vm.dismissPostSave() }
            )
        }
    }

    private var background: some View {
        ZStack { Theme.playerFaceGradient; SubtleScanlines() }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "B0E0F8"), intensity: 0.32)
            VStack {
                Rectangle().fill(Color.white.opacity(0.55)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color(hex: "0080C0").opacity(0.18)).frame(height: 1)
            }
            Text("record")
                .font(TimbreFont.fontBold(size: 22))
                .foregroundStyle(Color(hex: "004878"))
            HStack {
                Spacer()
                HomeButton(action: onGoHome).padding(.trailing, 12)
            }
        }
        .frame(height: 48)
    }

    // MARK: - Controls: [pause] [mic] [stop]

    private var controlRow: some View {
        HStack(spacing: 28) {
            // Pause (left)
            if !vm.isIdle {
                BubbleButton(
                    icon: vm.isPaused ? "play.fill" : "pause.fill",
                    size: 50,
                    color: Color(hex: "0088FF")
                ) { vm.togglePause() }
            } else {
                Color.clear.frame(width: 50, height: 50)
            }

            // Center: blue mic button
            micButton

            // Stop (right) — only while recording/paused
            if !vm.isIdle {
                BubbleButton(
                    icon: "stop.fill",
                    size: 50,
                    color: Color(hex: "0088FF")
                ) { vm.stopRecording() }
            } else {
                Color.clear.frame(width: 50, height: 50)
            }
        }
    }

    /// Blue pulsing mic button — matches the analyze "ready to transcribe" mic style
    private var micButton: some View {
        Button {
            if vm.isIdle { vm.startRecording() }
        } label: {
            ZStack {
                // Outer glow when recording
                if vm.isRecording {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "00FFFF").opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                }

                // Shadow
                Circle()
                    .fill(Color(hex: "004070").opacity(0.25))
                    .frame(width: 110, height: 110)
                    .offset(y: 3)

                // Main circle — cyan/blue gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "00D8FF"),
                                Color(hex: "0088FF"),
                                Color(hex: "0060C0"),
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 95
                        )
                    )
                    .frame(width: 110, height: 110)

                // Gloss
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .frame(width: 76, height: 42)
                    .offset(y: -20)

                // Border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color(hex: "0060C0").opacity(0.4)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 110, height: 110)

                // Mic icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: "00FFFF").opacity(0.5), radius: 4, y: 0)
            }
            .scaleEffect(vm.isRecording ? 1.06 : 1.0)
            .animation(
                vm.isRecording
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: vm.isRecording
            )
        }
        .buttonStyle(.plain)
        .disabled(!vm.isIdle)
        .opacity(vm.isIdle ? 1.0 : 0.85)
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        Text(formatTime(vm.recorder.elapsedTime))
            .font(TimbreFont.fontBold(size: 42))
            .foregroundStyle(vm.isRecording ? Color(hex: "CC0000") : Color(hex: "004878"))
            .monospacedDigit()
    }

    // MARK: - Live waveform (scrolls right as audio comes in)

    private var liveWaveform: some View {
        ChromeInset {
            GeometryReader { geo in
                let barWidth: CGFloat = 3
                let spacing: CGFloat = 1
                let totalBar = barWidth + spacing
                let visibleBars = Int(geo.size.width / totalBar)
                let samples = vm.recorder.waveformSamples
                let visible = samples.suffix(visibleBars)
                let midY = geo.size.height / 2

                Canvas { context, size in
                    for (i, sample) in visible.enumerated() {
                        let amplitude = CGFloat(sample)
                        let barH = max(2, amplitude * size.height * 0.85)
                        let x = CGFloat(i) * totalBar
                        let rect = CGRect(
                            x: x, y: midY - barH / 2,
                            width: barWidth, height: barH
                        )
                        context.fill(Path(rect), with: .color(Color(hex: "00D8FF")))
                    }
                }
            }
            .frame(height: 140)
            .background(
                LinearGradient(
                    colors: [Color(hex: "044060").opacity(0.85), Color(hex: "0868A0")],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .retroInset()
        }
        .frame(height: 146)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
