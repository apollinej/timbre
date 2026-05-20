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
    @State private var promptToast = false
    @State private var renamingSpeaker: Speaker?
    @State private var celebrationID: UUID?
    @State private var showFindReplace = false
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var editingBlockIndex: Int?
    @State private var editText = ""
    @State private var isEditMode = false
    @State private var showPasteSheet = false
    @State private var pasteText = ""
    private let orchestrator = AnalysisOrchestrator()

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

                if memo.status == .completed || memo.status == .analyzed {
                    HStack(spacing: 6) {
                        headerPill(
                            icon: isEditMode ? "checkmark" : "pencil",
                            label: isEditMode ? "done" : "edit"
                        ) {
                            if isEditMode { editingBlockIndex = nil }
                            isEditMode.toggle()
                        }
                        headerPill(icon: "magnifyingglass", label: "find") {
                            showFindReplace.toggle()
                        }
                        headerPill(icon: "sparkles", label: "prompt") {
                            requestAnalysis()
                        }
                        headerPill(icon: "square.and.arrow.up", label: "export") {
                            exportTranscript()
                        }
                        headerPill(icon: "doc.on.doc", label: "copy") {
                            copyTranscriptToClipboard()
                        }
                    }
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
                case .completed, .analyzed: transcriptContentView
                case .failed(let error): failedView(error)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Playback bar
            if memo.status == .completed || memo.status == .analyzed {
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
            if let toastText = activeToast {
                Text(toastText)
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
        .sheet(isPresented: $showPasteSheet) {
            pasteAnalysisSheet
        }
    }

    private var pasteAnalysisSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("paste your analysis")
                    .font(TimbreFont.fontBold(size: 16))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Button { showPasteSheet = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Text("the prompt is already on your clipboard. paste it into chatgpt or claude, then paste the response below.")
                .font(TimbreFont.font(size: 12))
                .foregroundStyle(Color(hex: "2090C8"))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            TextEditor(text: $pasteText)
                .font(.system(size: 13, design: .monospaced))
                .padding(8)
                .background(Color.white.opacity(0.5))
                .frame(minHeight: 280)
                .padding(.horizontal, 16)

            HStack {
                Spacer()
                TimbrePill("save", style: .primary) { savePastedAnalysis() }
            }
            .padding(16)
        }
        .frame(width: 560, height: 480)
        .background(Theme.iridescentSubtle)
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

        return VStack(spacing: 0) {
            if showFindReplace {
                FindReplaceBar(
                    findText: $findText,
                    replaceText: $replaceText,
                    onReplaceAll: { findAndReplaceAll() },
                    onClose: { showFindReplace = false }
                )
            }

            ScrollViewReader { proxy in
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
                                isEditing: isEditMode && editingBlockIndex == index,
                                isEditMode: isEditMode,
                                speakerVersion: viewModel.speakerVersion,
                                onTap: {
                                    if isEditMode {
                                        editingBlockIndex = index
                                    } else {
                                        Task {
                                            await viewModel.jumpToAndPlay(memo: memo, time: block.startTime)
                                        }
                                    }
                                },
                                onRenameSpeaker: {
                                    if let speaker = block.speaker {
                                        renamingSpeaker = speaker
                                    }
                                },
                                onStartEdit: {
                                    editingBlockIndex = index
                                },
                                onSaveEdit: { newText in
                                    saveSegmentEdit(
                                        segments: transcript.sortedSegments,
                                        blockIndex: index,
                                        merged: merged,
                                        newText: newText
                                    )
                                    editingBlockIndex = nil
                                },
                                onCancelEdit: {
                                    editingBlockIndex = nil
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

        showToast("copied to clipboard")
    }

    private func exportTranscript() {
        let formats = ExportFormat.allCases
        let panel = NSSavePanel()
        panel.nameFieldStringValue = memo.title
        panel.allowedContentTypes = [.plainText]

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 26))
        popup.addItems(withTitles: formats.map { "\($0.label) (.\($0.fileExtension))" })
        panel.accessoryView = popup

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let format = formats[popup.indexOfSelectedItem]
        guard let content = ExportService.export(memo: memo, format: format) else { return }

        // Ensure correct extension
        let finalURL: URL
        if url.pathExtension != format.fileExtension {
            finalURL = url.deletingPathExtension()
                .appendingPathExtension(format.fileExtension)
        } else {
            finalURL = url
        }
        try? content.write(to: finalURL, atomically: true, encoding: .utf8)
    }

    /// Single entry: if OpenAI key is set, run the API. If not, copy the
    /// prompt to clipboard and open the paste sheet so the user can run
    /// it in their own LLM and paste the result back.
    private func requestAnalysis() {
        let key = (KeychainService.read(key: "openai-api-key") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            Task { await viewModel.runAnalysis(memo: memo, context: modelContext) }
            showToast("analyzing\u{2026}")
        } else {
            copyManualPrompt()
            pasteText = memo.analysis?.detailedNotes ?? ""
            showPasteSheet = true
        }
    }

    private func copyManualPrompt() {
        guard let prompt = AnalysisPromptBuilder.manualPrompt(for: memo) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        showToast("prompt copied — paste into your favorite llm")
    }

    private func savePastedAnalysis() {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { showPasteSheet = false; return }

        let parsed = AnalysisPromptBuilder.parseManualResponse(trimmed)
        let analysis = memo.analysis ?? MemoAnalysis(analysisModelUsed: "manual-paste")
        analysis.summary = parsed.summary
        analysis.detailedNotes = parsed.detailedNotes
        analysis.dateAnalyzed = .now
        analysis.analysisModelUsed = "manual-paste"
        analysis.isStale = false

        analysis.actionItems.forEach { modelContext.delete($0) }
        analysis.openThreads.forEach { modelContext.delete($0) }
        analysis.keyDecisions.forEach { modelContext.delete($0) }

        analysis.actionItems = parsed.actionItems.map {
            let i = AnalysisItem(text: $0, sourceMemoID: memo.id, itemType: "action")
            modelContext.insert(i); return i
        }
        analysis.openThreads = parsed.threads.map {
            let i = AnalysisItem(text: $0, sourceMemoID: memo.id, itemType: "thread")
            modelContext.insert(i); return i
        }
        analysis.keyDecisions = parsed.decisions.map {
            let i = AnalysisItem(text: $0, sourceMemoID: memo.id, itemType: "decision")
            modelContext.insert(i); return i
        }

        if memo.analysis == nil {
            modelContext.insert(analysis)
            memo.analysis = analysis
        }
        memo.status = .analyzed
        try? modelContext.save()
        AnalysisDiskExport.writeIfPossible(memo)
        showPasteSheet = false
        showToast("analysis saved")
    }

    private func findAndReplaceAll() {
        guard let transcript = memo.transcript,
              !findText.isEmpty else { return }
        var count = 0
        for segment in transcript.sortedSegments {
            // Case-insensitive search
            if segment.text.localizedCaseInsensitiveContains(findText) {
                segment.text = segment.text.replacingOccurrences(
                    of: findText,
                    with: replaceText,
                    options: [.caseInsensitive]
                )
                count += 1
            }
        }
        if count > 0 {
            try? modelContext.save()
            viewModel.speakerVersion += 1
            try? TranscriptDiskExport.writeMemoTranscriptIfNeeded(memo)
            showToast("replaced in \(count) segment\(count == 1 ? "" : "s")")
        } else {
            showToast("not found")
        }
    }

    private func saveSegmentEdit(
        segments: [Segment],
        blockIndex: Int,
        merged: [MergedBlock],
        newText: String
    ) {
        guard blockIndex < merged.count else { return }
        let block = merged[blockIndex]
        let blockSegments = segments.filter { seg in
            seg.startTime >= block.startTime && seg.endTime <= block.endTime
                && seg.speaker?.id == block.speaker?.id
        }
        if blockSegments.count == 1 {
            blockSegments[0].text = newText
        } else if !blockSegments.isEmpty {
            // Put all edited text into first segment, clear the rest
            blockSegments[0].text = newText
            for seg in blockSegments.dropFirst() {
                seg.text = ""
            }
        }
        try? modelContext.save()
        viewModel.speakerVersion += 1
        try? TranscriptDiskExport.writeMemoTranscriptIfNeeded(memo)
    }

    private var activeToast: String? {
        if copiedToast { return "copied to clipboard" }
        if promptToast { return "prompt copied — paste into your favorite llm" }
        return nil
    }

    private func showToast(_ message: String) {
        copiedToast = false
        promptToast = false
        if message.contains("prompt") {
            withAnimation { promptToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { promptToast = false }
            }
        } else {
            withAnimation { copiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { copiedToast = false }
            }
        }
    }

    private func headerPill(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(TimbreFont.fontBold(size: 12))
            }
            .foregroundStyle(Color(hex: "0088FF"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
    let isEditing: Bool
    let isEditMode: Bool
    let speakerVersion: Int
    let onTap: () -> Void
    let onRenameSpeaker: () -> Void
    let onStartEdit: () -> Void
    let onSaveEdit: (String) -> Void
    let onCancelEdit: () -> Void

    @State private var localEditText = ""
    @FocusState private var editFocused: Bool

    // Force re-read speaker name when speakerVersion changes
    private var speakerName: String {
        let _ = speakerVersion
        return block.speaker?.effectiveName ?? "???"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
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

                if isEditing {
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $localEditText)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Color(hex: "043050"))
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color(hex: "00B0FF").opacity(0.6), lineWidth: 1)
                            )
                            .frame(minHeight: 60)
                            .focused($editFocused)
                            .onAppear {
                                localEditText = block.text
                                editFocused = true
                            }

                        HStack(spacing: 8) {
                            Button {
                                onSaveEdit(localEditText)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("save")
                                        .font(TimbreFont.fontBold(size: 11))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                )
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
                                .shadow(color: Color(hex: "00C8FF").opacity(0.3), radius: 3, y: 1)
                            }
                            .buttonStyle(.plain)

                            Button {
                                onCancelEdit()
                            } label: {
                                Text("cancel")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Color(hex: "0088C8"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // When edit mode is on, disable text selection so the tap
                    // reaches onTapGesture instead of being swallowed by selection.
                    if isEditMode {
                        Text(block.text)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Color(hex: "043050"))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture { onTap() }
                    } else {
                        Text(block.text)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Color(hex: "043050"))
                            .textSelection(.enabled)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture { onTap() }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            isActive
                ? Color(hex: "00C8FF").opacity(0.12)
                : isEditing
                    ? Color(hex: "00C8FF").opacity(0.06)
                    : Color.clear
        )
        .onChange(of: isEditing) { wasEditing, nowEditing in
            if wasEditing && !nowEditing && !localEditText.isEmpty && localEditText != block.text {
                onSaveEdit(localEditText)
            }
        }
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
