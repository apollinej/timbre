import SwiftUI
import SwiftData

// Iridescent silver background used across detail views
struct IridescentBackground: View {
    var body: some View {
        ZStack {
            // Base silver
            Color(hex: "C8C4D8")

            // Iridescent shift
            LinearGradient(
                colors: [
                    Color(hex: "D0C8E0"),
                    Color(hex: "C0CCE0"),
                    Color(hex: "D4C4D8"),
                    Color(hex: "C8D0E8"),
                    Color(hex: "D8CCE0"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Shimmer streaks
            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear,
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.white.opacity(0.15),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct TranscriptView: View {
    let memo: Memo
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TranscriptViewModel()
    @AppStorage("selectedModel") private var selectedModelRaw = WhisperModel.baseEn.rawValue
    @State private var copiedToast = false
    @State private var renamingSpeaker: Speaker?

    private var selectedModel: WhisperModel {
        WhisperModel(rawValue: selectedModelRaw) ?? .baseEn
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top chrome bar
            HStack {
                Text(memo.title.lowercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "2A4A70"))
                    .lineLimit(1)

                Spacer()

                if memo.status == .completed {
                    Button { copyTranscriptToClipboard() } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                            Text("copy")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: "3080C0"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "3080C0").opacity(0.1))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color(hex: "3080C0").opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Chrome toolbar gradient
                    LinearGradient(
                        colors: [
                            Color(hex: "D8D4E8"),
                            Color(hex: "C4C0D4"),
                            Color(hex: "CCC8DC"),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Top highlight line
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(height: 1)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            )

            // Waveform
            if !viewModel.waveformSamples.isEmpty {
                WaveformView(
                    samples: viewModel.waveformSamples,
                    progress: viewModel.playbackProgress
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "B8B4C8"))

                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 1)
            }

            // Main content
            Group {
                switch memo.status {
                case .imported: readyToTranscribeView
                case .transcribing: transcribingView
                case .completed: transcriptContentView
                case .failed(let error): failedView(error)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Playback bar
            if memo.status == .completed {
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 1)
                PlaybackBar(viewModel: viewModel)
            }
        }
        .background(IridescentBackground())
        .task(id: memo.id) {
            await viewModel.loadAudio(from: memo)
        }
        .overlay(alignment: .top) {
            if copiedToast {
                Text("copied to clipboard")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(hex: "3080C0"))
                    .foregroundStyle(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 40)
            }
        }
        .sheet(item: $renamingSpeaker) { speaker in
            SpeakerRenameSheet(speaker: speaker) { newName in
                viewModel.renameSpeaker(speaker, to: newName)
            }
        }
    }

    // MARK: - Ready to Transcribe

    private var readyToTranscribeView: some View {
        VStack(spacing: 14) {
            Image(systemName: "mic.fill")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(Color(hex: "6898B8"))

            Text("ready to transcribe")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "2A4A70"))

            Text("\(memo.formattedDuration) // \(selectedModel.displayName)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "6898B8"))

            Button {
                Task {
                    await viewModel.startTranscription(
                        memo: memo, model: selectedModel, context: modelContext
                    )
                }
            } label: {
                Text("[ start transcription ]")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4890D0"), Color(hex: "2868A8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        ZStack {
                            VStack {
                                Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                                Spacer()
                                Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1)
                            }
                            HStack {
                                Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)
                                Spacer()
                                Rectangle().fill(Color.black.opacity(0.15)).frame(width: 1)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Transcribing

    private var transcribingView: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: "3A3650"))
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4890D0"), Color(hex: "3080C0")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * memo.transcriptionProgress)
                }
                .overlay(
                    ZStack {
                        VStack {
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color.black.opacity(0.3)).frame(height: 1)
                        }
                    }
                )
            }
            .frame(width: 280, height: 12)

            Text("transcribing\u{2026}")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "2A4A70"))

            Text("\(Int(memo.transcriptionProgress * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "3080C0"))

            Button("[ cancel ]") {
                Task { await viewModel.cancelTranscription(memo: memo) }
            }
            .font(.system(size: 10, design: .monospaced))
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: "6898B8"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Transcript Content

    private var transcriptContentView: some View {
        let _ = viewModel.speakerVersion

        return ScrollViewReader { proxy in
            ScrollView {
                if let transcript = memo.transcript {
                    let merged = mergeSegments(transcript.sortedSegments)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(
                            Array(merged.enumerated()),
                            id: \.offset
                        ) { index, block in
                            MergedSegmentRow(
                                block: block,
                                isActive: isBlockActive(block),
                                onTap: {
                                    viewModel.seek(to: block.startTime)
                                    viewModel.play()
                                },
                                onRenameSpeaker: {
                                    if let speaker = block.speaker {
                                        renamingSpeaker = speaker
                                    }
                                }
                            )
                            .id(index)

                            if index < merged.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "B0ACC4").opacity(0.5))
                                    .frame(height: 1)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.currentTime) { _, newTime in
                        guard viewModel.isPlaying else { return }
                        let merged = mergeSegments(transcript.sortedSegments)
                        if let idx = merged.firstIndex(where: {
                            newTime >= $0.startTime && newTime < $0.endTime
                        }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    private func isBlockActive(_ block: MergedBlock) -> Bool {
        viewModel.isPlaying &&
        viewModel.currentTime >= block.startTime &&
        viewModel.currentTime < block.endTime
    }

    private func copyTranscriptToClipboard() {
        guard let transcript = memo.transcript else { return }
        let merged = mergeSegments(transcript.sortedSegments)
        let text = merged.map { block in
            let name = block.speaker?.effectiveName ?? "Unknown"
            return "\(name) (\(TimeFormatter.format(block.startTime)))\n\(block.text)"
        }.joined(separator: "\n\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        withAnimation { copiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedToast = false }
        }
    }

    private func mergeSegments(_ segments: [Segment]) -> [MergedBlock] {
        guard !segments.isEmpty else { return [] }
        var blocks: [MergedBlock] = []
        var currentSpeakerId = segments[0].speaker?.id
        var currentTexts: [String] = [segments[0].text]
        var currentStart = segments[0].startTime
        var currentEnd = segments[0].endTime
        var currentSpeaker = segments[0].speaker

        for segment in segments.dropFirst() {
            if segment.speaker?.id == currentSpeakerId {
                currentTexts.append(segment.text)
                currentEnd = segment.endTime
            } else {
                blocks.append(MergedBlock(
                    text: currentTexts.joined(separator: " "),
                    startTime: currentStart,
                    endTime: currentEnd,
                    speaker: currentSpeaker
                ))
                currentSpeakerId = segment.speaker?.id
                currentTexts = [segment.text]
                currentStart = segment.startTime
                currentEnd = segment.endTime
                currentSpeaker = segment.speaker
            }
        }
        blocks.append(MergedBlock(
            text: currentTexts.joined(separator: " "),
            startTime: currentStart,
            endTime: currentEnd,
            speaker: currentSpeaker
        ))
        return blocks
    }

    // MARK: - Failed

    private func failedView(_ error: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(Color(hex: "A85858"))

            Text("transcription failed")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "2A4A70"))

            Text(error)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "6898B8"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button("[ retry ]") {
                Task {
                    await viewModel.startTranscription(
                        memo: memo, model: selectedModel, context: modelContext
                    )
                }
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Color(hex: "3080C0"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Data Types

struct MergedBlock {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let speaker: Speaker?
}

// MARK: - Merged Segment Row

struct MergedSegmentRow: View {
    let block: MergedBlock
    let isActive: Bool
    let onTap: () -> Void
    let onRenameSpeaker: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Active indicator bar
            Rectangle()
                .fill(isActive ? Color(hex: "3080C0") : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    SpeakerBadge(speaker: block.speaker)
                        .onTapGesture { onRenameSpeaker() }

                    Text(TimeFormatter.format(block.startTime))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: "6898B8"))
                }

                Text(block.text)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "1A2838"))
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            isActive
                ? Color(hex: "3080C0").opacity(0.08)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Speaker Rename Sheet

struct SpeakerRenameSheet: View {
    let speaker: Speaker
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("rename speaker")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "2A4A70"))

            Text("applies to all segments from this speaker")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(hex: "6898B8"))

            TextField("Name", text: $text)
                .textFieldStyle(.squareBorder)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit { save() }

            HStack {
                Button("[ cancel ]") { dismiss() }
                    .font(.system(size: 10, design: .monospaced))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: "6898B8"))
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("[ save ]") { save() }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "3080C0"))
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    ).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            text = speaker.displayName ?? speaker.label
            isFocused = true
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}
