import SwiftUI
import SwiftData

struct IridescentBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "E8F8FF")

            Theme.iridescent

            LinearGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear,
                    Color(hex: "00FFFF").opacity(0.12),
                    Color.clear,
                    Color.white.opacity(0.22),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            SubtleScanlines()
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
    @State private var celebrationID: UUID?

    private var selectedModel: WhisperModel {
        WhisperModel(rawValue: selectedModelRaw) ?? .baseEn
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    PixelStar(color: Color(hex: "00C8FF"))
                    Text(memo.title.lowercased())
                        .font(TimbreFont.fontBold(size: 16))
                        .foregroundStyle(Color(hex: "044060"))
                        .lineLimit(2)
                }

                Spacer()

                if memo.status == .completed {
                    Button { copyTranscriptToClipboard() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                            Text("copy")
                                .font(TimbreFont.fontBold(size: 14))
                        }
                        .foregroundStyle(Color(hex: "0088FF"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color(hex: "C8F0FF")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color(hex: "00B0FF").opacity(0.6), lineWidth: 1.5)
                        )
                        .shadow(color: Color(hex: "00C8FF").opacity(0.25), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    BrushedMetal(baseColor: Color(hex: "B0E0F8"), intensity: 0.32)
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.55))
                            .frame(height: 1)
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: "0080C0").opacity(0.18))
                            .frame(height: 1)
                    }
                }
            )

            // Waveform — click/drag to seek (synced with playback bar)
            if !viewModel.waveformSamples.isEmpty {
                WaveformView(
                    samples: viewModel.waveformSamples,
                    progress: viewModel.playbackProgress,
                    onSeek: { fraction in
                        let time = fraction * viewModel.duration
                        viewModel.seek(to: time)
                    }
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "D8F4FF"), Color(hex: "B8E8FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Rectangle()
                    .fill(Color(hex: "0080C0").opacity(0.2))
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
                    .fill(Color(hex: "0080C0").opacity(0.22))
                    .frame(height: 1)
                PlaybackBar(memo: memo, viewModel: viewModel)
            }
            }
            .background(IridescentBackground())

            if let id = celebrationID {
                TranscriptCelebrationOverlay(runID: id) {
                    celebrationID = nil
                }
                .id(id)
                .transition(.opacity)
            }
        }
        .task(id: memo.id) {
            await viewModel.loadAudio(from: memo)
        }
        .onChange(of: memo.status) { oldStatus, newStatus in
            if case .transcribing = oldStatus, case .completed = newStatus {
                withAnimation(.easeOut(duration: 0.2)) {
                    celebrationID = UUID()
                }
            }
        }
        .overlay(alignment: .top) {
            if copiedToast {
                Text("copied to clipboard")
                    .font(TimbreFont.fontBold(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00B0FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .foregroundStyle(.white)
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 48)
            }
        }
        .sheet(item: $renamingSpeaker) { speaker in
            SpeakerRenameSheet(speaker: speaker) { newName in
                viewModel.renameSpeaker(speaker, to: newName)
                try? modelContext.save()
                TranscriptDiskExport.syncAllMemos(modelContext: modelContext)
            }
        }
    }

    // MARK: - Ready to Transcribe

    private var readyToTranscribeView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "00FFFF").opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D8FF"), Color(hex: "0088FF")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("ready to transcribe")
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "044060"))

            Text("\(memo.formattedDuration) // \(selectedModel.displayName)")
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "0088C8"))

            Button {
                Task {
                    await viewModel.startTranscription(
                        memo: memo, model: selectedModel, context: modelContext
                    )
                }
            } label: {
                Text("[ start transcription ]")
                    .font(TimbreFont.fontBold(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00C8FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5))
                    .shadow(color: Color(hex: "00FFFF").opacity(0.4), radius: 8, y: 3)
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
                    Rectangle().fill(Color(hex: "044060"))
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00FF88"), Color(hex: "00C8FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * memo.transcriptionProgress)
                }
                .overlay(
                    ZStack {
                        VStack {
                            Rectangle().fill(Color.white.opacity(0.35)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color.black.opacity(0.25)).frame(height: 1)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(width: 320, height: 16)

            Text("transcribing\u{2026}")
                .font(TimbreFont.fontBold(size: 17))
                .foregroundStyle(Color(hex: "044060"))

            Text("\(Int(memo.transcriptionProgress * 100))%")
                .font(TimbreFont.fontBold(size: 16))
                .foregroundStyle(Color(hex: "0088FF"))

            Button("[ cancel ]") {
                Task { await viewModel.cancelTranscription(memo: memo) }
            }
            .font(Theme.bodyFont)
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: "0088C8"))
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
                                    Task {
                                        await viewModel.jumpToAndPlay(memo: memo, time: block.startTime)
                                    }
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
                                    .fill(Color(hex: "40C8FF").opacity(0.35))
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
            let name = (block.speaker?.effectiveName ?? "unknown").lowercased()
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF4080"), Color(hex: "FF8080")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("transcription failed")
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "044060"))

            Text(error)
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "0088C8"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("[ retry ]") {
                Task {
                    await viewModel.startTranscription(
                        memo: memo, model: selectedModel, context: modelContext
                    )
                }
            }
            .font(TimbreFont.fontBold(size: 16))
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00B0FF"), Color(hex: "0080DD")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
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
            Group {
                if isActive {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00FFFF"), Color(hex: "0088FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Rectangle().fill(Color.clear)
                }
            }
            .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Button { onRenameSpeaker() } label: {
                        SpeakerBadge(speaker: block.speaker)
                    }
                    .buttonStyle(.plain)

                    Text(TimeFormatter.format(block.startTime))
                        .font(Theme.smallMetaFont)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "0088C8"))
                        .onTapGesture { onTap() }
                }

                Text(block.text)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color(hex: "043050"))
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            isActive
                ? Color(hex: "00C8FF").opacity(0.12)
                : Color.clear
        )
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
                .font(TimbreFont.fontBold(size: 17))
                .foregroundStyle(Color(hex: "044060"))

            Text("applies to all segments from this speaker")
                .font(Theme.captionFont)
                .foregroundStyle(Color(hex: "0088C8"))

            TextField("name", text: $text)
                .textFieldStyle(.squareBorder)
                .font(Theme.bodyFont)
                .focused($isFocused)
                .onSubmit { save() }

            HStack {
                Button("[ cancel ]") { dismiss() }
                    .font(Theme.bodyFont)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: "0088C8"))
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("[ save ]") { save() }
                    .font(TimbreFont.fontBold(size: 15))
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5))
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    ).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            LinearGradient(
                colors: [Color(hex: "F0FCFF"), Color(hex: "D0E8FF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .textCase(.lowercase)
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
