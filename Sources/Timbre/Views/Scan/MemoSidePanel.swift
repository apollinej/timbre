import AppKit
import SwiftData
import SwiftUI

struct MemoSidePanel: View {
    @Environment(\.modelContext) private var modelContext
    let memo: Memo
    let onClose: () -> Void
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let onOpenAnalyze: () -> Void

    @State private var scrollTarget: String?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showPasteSheet = false
    @State private var pasteText = ""
    @State private var infoToast: String?
    private let orchestrator = AnalysisOrchestrator()

    /// All cards render unconditionally now (empty cards show a prompt button),
    /// so every section is always a valid jump target.
    private var availableSections: [String] {
        ["metadata", "summary", "notes", "key decisions", "action items", "open questions", "transcript"]
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        titleCard.id("metadata")
                        summaryCard.id("summary")
                        notesCard.id("notes")
                        decisionsCard.id("key decisions")
                        actionItemsCard.id("action items")
                        questionsCard.id("open questions")
                        transcriptSection.id("transcript")
                    }
                    .padding(16)
                }
                .onChange(of: scrollTarget) { _, target in
                    if let target {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        scrollTarget = nil
                    }
                }
            }

            sectionJumper
        }
        .frame(minWidth: 400, idealWidth: 460)
        .background(
            LinearGradient(
                colors: [Color(hex: "F0FCFF"), Color(hex: "E0F4FF")],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: "0080C0").opacity(0.2))
                .frame(width: 1),
            alignment: .leading
        )
        .sheet(isPresented: $showPasteSheet) {
            pasteAnalysisSheet
        }
        .overlay(alignment: .top) {
            if let text = infoToast {
                Text(text)
                    .font(TimbreFont.fontBold(size: 12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "0088FF")))
                    .foregroundStyle(.white)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "C0E8F8"), intensity: 0.25)

            HStack(spacing: 10) {
                if onPrevious != nil {
                    Button { onPrevious?() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "0088FF"))
                    }
                    .buttonStyle(.plain)
                }

                Text(memo.title)
                    .font(TimbreFont.fontBold(size: 15))
                    .foregroundStyle(Color(hex: "044060"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                if onNext != nil {
                    Button { onNext?() } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "0088FF"))
                    }
                    .buttonStyle(.plain)
                }

                Button { onOpenAnalyze() } label: {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
                .help("open in decode")

                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 42)
    }

    // MARK: - Title card (first card: title + metadata)

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(memo.title)
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "044060"))
                .lineLimit(3)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "0088C8"))
                Text(memo.displayDate.formatted(date: .long, time: .shortened))
                    .font(TimbreFont.font(size: 13))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text(memo.formattedDuration)
                    .font(TimbreFont.fontBold(size: 13))
                    .foregroundStyle(Color(hex: "0088C8"))
            }

            if let segs = memo.transcript?.segments {
                let speakers = uniqueSpeakers(from: segs)
                if !speakers.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(speakers) { spk in
                            SpeakerBadge(speaker: spk)
                        }
                    }
                }
            }

            if let context = memo.context, !context.isEmpty {
                Text(context)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color(hex: "2090C8"))
                    .italic()
            }
        }
        .sectionCard()
    }

    // MARK: - Analysis cards (always rendered; empty cards show a prompt button)

    private var summaryCard: some View {
        analysisCard(title: "summary", isEmpty: (memo.analysis?.summary ?? "").isEmpty) {
            Text(memo.analysis?.summary ?? "")
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .textSelection(.enabled)
        }
    }

    private var notesCard: some View {
        analysisCard(title: "notes", isEmpty: (memo.analysis?.detailedNotes ?? "").isEmpty) {
            Text(memo.analysis?.detailedNotes ?? "")
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .textSelection(.enabled)
        }
    }

    private var decisionsCard: some View {
        analysisCard(
            title: "key decisions",
            isEmpty: (memo.analysis?.keyDecisions ?? []).isEmpty
        ) {
            itemList(memo.analysis?.keyDecisions ?? [])
        }
    }

    private var actionItemsCard: some View {
        analysisCard(
            title: "action items",
            isEmpty: (memo.analysis?.actionItems ?? []).isEmpty
        ) {
            itemList(memo.analysis?.actionItems ?? [])
        }
    }

    private var questionsCard: some View {
        analysisCard(
            title: "open questions",
            isEmpty: (memo.analysis?.openThreads ?? []).isEmpty
        ) {
            itemList(memo.analysis?.openThreads ?? [])
        }
    }

    @ViewBuilder
    private func analysisCard<Content: View>(
        title: String,
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "0088FF"))
            if isEmpty {
                promptButton
            } else {
                content()
            }
        }
        .sectionCard()
    }

    private var promptButton: some View {
        Button { requestAnalysis() } label: {
            HStack(spacing: 5) {
                if isAnalyzing {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                }
                Text(isAnalyzing ? "analyzing\u{2026}" : "prompt")
                    .font(TimbreFont.fontBold(size: 12))
            }
            .foregroundStyle(isAnalyzing ? Color(hex: "0088FF") : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    isAnalyzing
                        ? Color(hex: "E0F0FF")
                        : Color(hex: "0088FF")
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnalyzing)
    }

    private func itemList(_ items: [AnalysisItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(Color(hex: "0088FF").opacity(0.4))
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(item.text)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Color(hex: "043050"))
                }
            }
        }
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("transcript")
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "0088FF"))

            if let transcript = memo.transcript {
                ForEach(transcript.sortedSegments.prefix(50)) { seg in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            if let spk = seg.speaker {
                                Text(spk.effectiveName.lowercased())
                                    .font(TimbreFont.fontBold(size: 11))
                                    .foregroundStyle(Color(hex: spk.colorHex))
                            }
                            Text(TimeFormatter.format(seg.startTime))
                                .font(TimbreFont.font(size: 10))
                                .foregroundStyle(Color(hex: "0088C8"))
                        }
                        Text(seg.text)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Color(hex: "043050"))
                    }
                    .padding(.vertical, 2)
                }
            } else {
                Text("no transcript available")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
        .sectionCard()
    }

    // MARK: - Analysis trigger (single smart entry point)

    /// One button → two paths:
    /// - If OpenAI key is set in Keychain, run the API analysis directly.
    /// - If not, copy the manual prompt to clipboard and open the paste sheet
    ///   so the user can run it in their own LLM and paste the result back.
    private func requestAnalysis() {
        let key = (KeychainService.read(key: "openai-api-key") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            Task { await runAnalysis() }
        } else {
            copyPrompt()
            pasteText = memo.analysis?.detailedNotes ?? ""
            showPasteSheet = true
        }
    }

    // MARK: - Paste-your-own analysis

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

            Text("copy the prompt, paste it into chatgpt or claude, then paste the response below — it will appear as the notes for this memo.")
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

    private func copyPrompt() {
        guard let prompt = AnalysisPromptBuilder.manualPrompt(for: memo) else {
            analysisError = "no transcript to build prompt from"
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        showToast("prompt copied — paste into chatgpt or claude")
    }

    private func savePastedAnalysis() {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { showPasteSheet = false; return }

        let analysis = memo.analysis ?? MemoAnalysis(analysisModelUsed: "manual-paste")
        analysis.detailedNotes = trimmed
        analysis.dateAnalyzed = .now
        analysis.analysisModelUsed = "manual-paste"
        analysis.isStale = false

        if memo.analysis == nil {
            modelContext.insert(analysis)
            memo.analysis = analysis
        }
        memo.status = .analyzed
        try? modelContext.save()
        showPasteSheet = false
        showToast("analysis saved")
    }

    private func showToast(_ text: String) {
        withAnimation { infoToast = text }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation { infoToast = nil }
            }
        }
    }

    private func runAnalysis() async {
        guard !isAnalyzing, let transcript = memo.transcript else { return }
        isAnalyzing = true
        analysisError = nil
        defer { isAnalyzing = false }

        let text = transcript.sortedSegments.map { seg in
            let name = seg.speaker?.effectiveName ?? "Speaker"
            return "[\(name)] (\(TimeFormatter.format(seg.startTime)))\n\(seg.text)"
        }.joined(separator: "\n\n")

        do {
            let result = try await orchestrator.runFullAnalysis(
                transcript: text,
                title: memo.title,
                duration: memo.duration,
                date: memo.dateRecorded ?? memo.dateImported
            )
            writeAnalysis(result)
            showToast("analysis saved")
        } catch {
            analysisError = error.localizedDescription
            showToast(error.localizedDescription)
        }
    }

    private func writeAnalysis(_ result: FullAnalysisResult) {
        let analysis = memo.analysis ?? MemoAnalysis(analysisModelUsed: "openai-gpt-4o")
        analysis.summary = result.summary
        analysis.detailedNotes = result.detailedNotes
        analysis.dateAnalyzed = .now
        analysis.analysisModelUsed = "openai-gpt-4o"
        analysis.isStale = false

        analysis.actionItems.forEach { modelContext.delete($0) }
        analysis.openThreads.forEach { modelContext.delete($0) }
        analysis.keyDecisions.forEach { modelContext.delete($0) }

        analysis.actionItems = result.actionItems.map {
            makeItem($0, type: "action")
        }
        analysis.openThreads = result.threads.map {
            makeItem($0, type: "thread")
        }
        analysis.keyDecisions = result.decisions.map {
            makeItem($0, type: "decision")
        }

        if memo.analysis == nil {
            modelContext.insert(analysis)
            memo.analysis = analysis
        }
        memo.status = .analyzed
        try? modelContext.save()
    }

    private func makeItem(_ text: String, type: String) -> AnalysisItem {
        let item = AnalysisItem(text: text, sourceMemoID: memo.id, itemType: type)
        modelContext.insert(item)
        return item
    }

    // MARK: - Section jumper (bottom bar)

    @State private var showJumpMenu = false

    private var sectionJumper: some View {
        HStack(spacing: 8) {
            Spacer()

            Button { jumpDirection(-1) } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "0088FF"))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            // Jump to section dropdown
            Button { showJumpMenu.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                    Text("jump to")
                        .font(TimbreFont.fontBold(size: 11))
                }
                .foregroundStyle(Color(hex: "0088FF"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(Color(hex: "F0FCFF"))
                        .overlay(Capsule().strokeBorder(Color(hex: "0080C0").opacity(0.3)))
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showJumpMenu) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableSections, id: \.self) { section in
                        Button {
                            scrollTarget = section
                            currentSectionIndex = availableSections.firstIndex(of: section) ?? 0
                            showJumpMenu = false
                        } label: {
                            Text(section)
                                .font(TimbreFont.font(size: 13))
                                .foregroundStyle(Color(hex: "044060"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 180)
                .padding(.vertical, 4)
            }

            Button { jumpDirection(1) } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "0088FF"))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.vertical, 6)
        .background(BrushedMetal(baseColor: Color(hex: "C0E8F8"), intensity: 0.22))
    }

    @State private var currentSectionIndex = 0

    private func jumpDirection(_ direction: Int) {
        let sections = availableSections
        guard !sections.isEmpty else { return }
        let newIndex = max(0, min(sections.count - 1, currentSectionIndex + direction))
        currentSectionIndex = newIndex
        scrollTarget = sections[newIndex]
    }

    // MARK: - Helpers

    private func uniqueSpeakers(from segments: [Segment]) -> [Speaker] {
        var seen = Set<UUID>()
        var result: [Speaker] = []
        for seg in segments {
            if let s = seg.speaker, !seen.contains(s.id) {
                seen.insert(s.id)
                result.append(s)
            }
        }
        return result
    }
}

// MARK: - Section card modifier

extension View {
    func sectionCard() -> some View {
        self
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "40C8FF").opacity(0.25))
            )
    }
}
