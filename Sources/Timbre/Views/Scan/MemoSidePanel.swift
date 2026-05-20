import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MemoSidePanel: View {
    @Environment(\.modelContext) private var modelContext
    let memo: Memo
    let onClose: () -> Void
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let onOpenAnalyze: () -> Void

    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showPasteSheet = false
    @State private var pasteText = ""
    @State private var infoToast: String?
    private let orchestrator = AnalysisOrchestrator()

    /// All cards render unconditionally. Notes is second-to-last
    /// because the body is long; transcript is the final stop.
    private var availableSections: [String] {
        ["header", "summary", "key decisions", "action items", "open questions", "notes", "transcript"]
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            titleCard.id("header")
                            actionsRow
                            summaryCard.id("summary")
                            decisionsCard.id("key decisions")
                            actionItemsCard.id("action items")
                            questionsCard.id("open questions")
                            notesCard.id("notes")
                            transcriptSection.id("transcript")
                        }
                        .padding(16)
                    }

                    sectionJumper(proxy: proxy)
                }
            }
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
            BrushedMetal(baseColor: Color(hex: "98D4F8"), intensity: 0.34)
            VStack {
                Rectangle().fill(Color.white.opacity(0.4)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color(hex: "0080C0").opacity(0.22)).frame(height: 1)
            }

            HStack(spacing: 10) {
                if onPrevious != nil {
                    BubbleButton(
                        icon: "chevron.left",
                        size: 26,
                        color: Color(hex: "0088FF"),
                        action: { onPrevious?() }
                    )
                }

                Spacer()

                if onNext != nil {
                    BubbleButton(
                        icon: "chevron.right",
                        size: 26,
                        color: Color(hex: "0088FF"),
                        action: { onNext?() }
                    )
                }

                BubbleButton(
                    icon: "arrow.up.forward",
                    size: 26,
                    color: Color(hex: "00D8A0"),
                    action: onOpenAnalyze
                )

                BubbleButton(
                    icon: "xmark",
                    size: 26,
                    color: Color(hex: "7090B0"),
                    action: onClose
                )
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 48)
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

    // MARK: - Actions banner (sits directly under the header card)

    private var actionsRow: some View {
        HStack(spacing: 8) {
            TimbrePromptPill(label: "prompt", isBusy: isAnalyzing) {
                requestAnalysis()
            }
            TimbreEditPill(label: "edit") {
                pasteText = AnalysisPromptBuilder.renderAnalysisMarkdown(memo.analysis)
                showPasteSheet = true
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Analysis cards (display only; actions live in the banner above)

    private var summaryCard: some View {
        analysisCard(title: "summary") {
            Text(memo.analysis?.summary ?? "")
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .textSelection(.enabled)
        }
    }

    private var notesCard: some View {
        analysisCard(title: "notes") {
            Text(memo.analysis?.detailedNotes ?? "")
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .textSelection(.enabled)
        }
    }

    private var decisionsCard: some View {
        analysisCard(title: "key decisions") {
            itemList(memo.analysis?.keyDecisions ?? [])
        }
    }

    private var actionItemsCard: some View {
        analysisCard(title: "action items") {
            itemList(memo.analysis?.actionItems ?? [])
        }
    }

    private var questionsCard: some View {
        analysisCard(title: "open questions") {
            itemList(memo.analysis?.openThreads ?? [])
        }
    }

    @ViewBuilder
    private func analysisCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "0088FF"))
            content()
        }
        .sectionCard()
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
        VStack(alignment: .leading, spacing: 0) {
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

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "00A058"))
                Text("prompt copied to clipboard — paste it into chatgpt or claude, then paste the response below (or upload a .md file).")
                    .font(TimbreFont.font(size: 12))
                    .foregroundStyle(Color(hex: "044060"))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            HStack(spacing: 8) {
                TimbrePill("re-copy prompt", style: .secondary) { copyPrompt() }
                TimbrePill("upload .md file", style: .secondary) { uploadMarkdown() }
                Spacer()
            }
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
        .frame(width: 600, height: 540)
        .background(Theme.iridescentSubtle)
    }

    private func copyPrompt() {
        guard let prompt = AnalysisPromptBuilder.manualPrompt(for: memo) else {
            analysisError = "no transcript to build prompt from"
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        showToast("prompt copied to clipboard")
    }

    private func uploadMarkdown() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        var types: [UTType] = [.plainText, .text]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        if let markdown = UTType(filenameExtension: "markdown") { types.append(markdown) }
        panel.allowedContentTypes = types
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            pasteText = text
        } else {
            showToast("could not read file")
        }
    }

    private func savePastedAnalysis() {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { showPasteSheet = false; return }

        let parsed = AnalysisPromptBuilder.parseManualResponse(trimmed)
        writeAnalysis(parsed)
        memo.analysis?.analysisModelUsed = "manual-paste"
        try? modelContext.save()
        showPasteSheet = false
        showToast("analysis saved")
    }

    /// Used by the "Seed demo Debrief data" action in settings —
    /// not shown in the browse side panel itself.
    static var sampleResponse: String {
        """
        ## SUMMARY
        The team aligned on positioning around active duration and the cultural shift away from algorithmic feeds. Major decision: lead with the gatekeeper framing rather than the tooling story, with a credibility-first interview as the opener.

        ## NOTES
        ### Positioning
        - Active duration vs. supply/demand axis — apolline framed the discovery problem getting worse as AI music supply goes infinite while attention stays fixed
        - The new filter function is downstream of the value layer; we move up the stack from creation tools to curation
        - idan pushed for three buckets: legal, technical, cultural — cultural feels most defensible

        ### Discovery & gatekeeping
        - Tiktok analog from idan's experience at google shopping in 2020 — supply shock + curation gap
        - "Gatekeeper" as a frame: people already know who the labels are; making that explicit is more honest than pretending we have a neutral algorithm

        ## DECISIONS
        - Lead the launch story with gatekeeper/cultural framing, not the music-creation-tools narrative
        - Open with an interview-format piece (apolline) instead of a polished video
        - Defer the deep-dive video until after the interview lands

        ## ACTIONS
        - apolline: draft the interview outline and three target outlets by friday
        - idan: pull together the supply-shock + curation deck slides from the partnership convo
        - apolline: write up the gatekeeper framing in 2-3 paragraphs so it's quotable
        - both: review polish/perfectionism risk before next sync

        ## QUESTIONS
        - Do we name specific gatekeepers (labels) or keep it abstract?
        - What's the actual ask of the interviewer — a profile or a debate?
        - Is the partnership angle a distraction from the cultural framing, or the proof point for it?
        """
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
    @State private var currentSectionIndex = 0

    private func sectionJumper(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 10) {
            Spacer()

            BubbleButton(
                icon: "chevron.up",
                size: 26,
                color: Color(hex: "0088FF"),
                action: { jumpDirection(-1, proxy: proxy) }
            )

            Button { showJumpMenu.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11, weight: .bold))
                    Text(availableSections[currentSectionIndex])
                        .font(TimbreFont.fontBold(size: 11))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showJumpMenu) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(availableSections.enumerated()), id: \.offset) { idx, section in
                        Button {
                            currentSectionIndex = idx
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(section, anchor: .top)
                            }
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

            BubbleButton(
                icon: "chevron.down",
                size: 26,
                color: Color(hex: "0088FF"),
                action: { jumpDirection(1, proxy: proxy) }
            )

            Spacer()
        }
        .padding(.vertical, 8)
        .background(BrushedMetal(baseColor: Color(hex: "98D4F8"), intensity: 0.34))
        .overlay(
            Rectangle()
                .fill(Color(hex: "0080C0").opacity(0.22))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func jumpDirection(_ direction: Int, proxy: ScrollViewProxy) {
        let sections = availableSections
        guard !sections.isEmpty else { return }
        let newIndex = max(0, min(sections.count - 1, currentSectionIndex + direction))
        guard newIndex != currentSectionIndex || direction == 0 else {
            // Already clamped — still scroll for visible feedback if at an edge.
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(sections[newIndex], anchor: .top)
            }
            return
        }
        currentSectionIndex = newIndex
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(sections[newIndex], anchor: .top)
        }
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
