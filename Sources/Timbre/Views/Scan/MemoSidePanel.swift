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
    private let orchestrator = AnalysisOrchestrator()

    /// Only the sections that actually have anchors in the current view —
    /// avoids jump-to-section landing on a missing ID when no analysis exists.
    private var availableSections: [String] {
        var s: [String] = ["metadata"]
        if let analysis = memo.analysis {
            if let summary = analysis.summary, !summary.isEmpty { s.append("summary") }
            if let notes = analysis.detailedNotes, !notes.isEmpty { s.append("notes") }
            if !analysis.openThreads.isEmpty { s.append("open questions") }
            if !analysis.keyDecisions.isEmpty { s.append("key decisions") }
            if !analysis.actionItems.isEmpty { s.append("action items") }
        }
        s.append("transcript")
        return s
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        metadataSection.id("metadata")
                        if let analysis = memo.analysis {
                            analysisSection(analysis, proxy: proxy)
                        }
                        transcriptSection.id("transcript")
                        playButton
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

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "0088C8"))
                Text(memo.displayDate.formatted(date: .long, time: .shortened))
                    .font(TimbreFont.font(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text(memo.formattedDuration)
                    .font(TimbreFont.fontBold(size: 14))
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

    // MARK: - Analysis

    private func analysisSection(
        _ analysis: MemoAnalysis,
        proxy: ScrollViewProxy
    ) -> some View {
        Group {
            if let s = analysis.summary, !s.isEmpty {
                textBlock("summary", content: s).id("summary")
            }
            if let n = analysis.detailedNotes, !n.isEmpty {
                textBlock("notes", content: n).id("notes")
            }
            if !analysis.openThreads.isEmpty {
                itemBlock("open questions", items: analysis.openThreads)
                    .id("open questions")
            }
            if !analysis.keyDecisions.isEmpty {
                itemBlock("key decisions", items: analysis.keyDecisions)
                    .id("key decisions")
            }
            if !analysis.actionItems.isEmpty {
                itemBlock("action items", items: analysis.actionItems)
                    .id("action items")
            }
        }
    }

    private func textBlock(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "0088FF"))
            Text(content)
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .textSelection(.enabled)
        }
        .sectionCard()
    }

    private func itemBlock(_ title: String, items: [AnalysisItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(TimbreFont.fontBold(size: 15))
                .foregroundStyle(Color(hex: "0088FF"))
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
        .sectionCard()
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

    // MARK: - Action buttons

    private var playButton: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer()
                TimbrePill("open in decode", style: .secondary) { onOpenAnalyze() }
                analyzeButton
                Spacer()
            }

            if let err = analysisError {
                Text(err)
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "CC2040"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var analyzeButton: some View {
        let label = memo.analysis == nil ? "analyze" : "re-analyze"
        if isAnalyzing {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("analyzing\u{2026}")
                    .font(TimbreFont.fontBold(size: 12))
                    .foregroundStyle(Color(hex: "0088FF"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(hex: "E0F0FF")))
        } else if memo.transcript != nil {
            TimbrePill(label, style: .primary) {
                Task { await runAnalysis() }
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
        } catch {
            analysisError = error.localizedDescription
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
