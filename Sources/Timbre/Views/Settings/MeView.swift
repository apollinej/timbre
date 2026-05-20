import SwiftData
import SwiftUI

struct MeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var apiKey = ""
    @State private var keySaved = false
    @State private var keyError: String?
    @State private var seedToast: String?
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Theme.iridescentSubtle.ignoresSafeArea()
            SubtleScanlines()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 20) {
                        aiProviderSection
                        apiKeySection
                        developerSection
                        aboutSection
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 400)
        .onAppear {
            apiKey = KeychainService.read(key: "openai-api-key") ?? ""
        }
    }

    private var header: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "A8D8F8"), intensity: 0.3)
            HStack {
                Text("settings")
                    .font(TimbreFont.fontBold(size: 22))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 48)
    }

    private var aiProviderSection: some View {
        sectionCard("ai provider") {
            HStack {
                Text("model")
                    .font(TimbreFont.font(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text("openai gpt-4o")
                    .font(TimbreFont.fontBold(size: 14))
                    .foregroundStyle(Color(hex: "0088FF"))
            }
        }
    }

    private var apiKeySection: some View {
        sectionCard("api key") {
            VStack(alignment: .leading, spacing: 10) {
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(hex: "0080C0").opacity(0.3))
                    )

                HStack {
                    TimbrePill("save key", style: .primary) { saveKey() }

                    if keySaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("saved")
                                .font(TimbreFont.font(size: 12))
                                .foregroundStyle(.green)
                        }
                    }

                    if let err = keyError {
                        Text(err)
                            .font(TimbreFont.font(size: 12))
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }

                Text("your key is stored locally in keychain, never transmitted except to openai")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
    }

    private var developerSection: some View {
        sectionCard("developer") {
            VStack(alignment: .leading, spacing: 12) {
                Text("seed 5 demo memos covering every analysis state — un-analyzed, fresh, partially answered, fully resolved, and summary-only. useful for screenshots and trying the app end-to-end. delete any of them from browse afterward.")
                    .font(TimbreFont.font(size: 12))
                    .foregroundStyle(Color(hex: "2090C8"))

                HStack {
                    TimbrePill("seed demo data", style: .primary) { seedDemoData() }
                    if let t = seedToast {
                        Text(t)
                            .font(TimbreFont.font(size: 12))
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }

                Divider()
                    .padding(.vertical, 4)

                Text("danger zone — deletes every memo, analysis, and .md file under your storage root. cannot be undone. used to reset the app for screenshots or a fresh setup.")
                    .font(TimbreFont.font(size: 12))
                    .foregroundStyle(Color(hex: "B04020"))

                HStack {
                    Button { showResetConfirm = true } label: {
                        Text("reset all data")
                            .font(TimbreFont.fontBold(size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF6058"), Color(hex: "CC2040")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                            )
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .confirmationDialog(
            "delete every memo and analysis?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("delete everything", role: .destructive) { resetAllData() }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("this removes all memos, transcripts, analyses, and .md files. cannot be undone.")
        }
    }

    private func seedDemoData() {
        let now = Date()
        let cal = Calendar.current
        func daysAgo(_ n: Int, hour: Int = 14, minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0,
                     of: cal.date(byAdding: .day, value: -n, to: now) ?? now) ?? now
        }

        // 1. Un-analyzed — to demo the empty cards and prompt button
        seedMemo(
            title: "investor meeting prep",
            date: daysAgo(1, hour: 20, minute: 32),
            duration: 27 * 60 + 14,
            analysisMarkdown: nil
        )

        // 2. Full analysis, no resolutions yet — to demo fresh Debrief items
        seedMemo(
            title: "y2k research session",
            date: daysAgo(5, hour: 15, minute: 0),
            duration: 83 * 60 + 45,
            analysisMarkdown: Self.demo_y2kResearch
        )

        // 3. Partial resolutions — some answered, some pending
        let designCrit = seedMemo(
            title: "design crit with idan",
            date: daysAgo(8, hour: 11, minute: 0),
            duration: 42 * 60 + 30,
            analysisMarkdown: Self.demo_designCrit
        )
        if let memo = designCrit, let analysis = memo.analysis {
            // Answer the first open thread + first decision
            if let t = analysis.openThreads.first {
                t.resolution = "decided the pixel-grid alignment matters more than the gradient — idan was right, polish ships."
                t.isResolved = true
            }
            if let d = analysis.keyDecisions.first {
                d.resolution = "shipped friday after the speaker-rename merged. no regressions reported."
                d.isResolved = true
            }
            // Complete the first action
            if let a = analysis.actionItems.first {
                a.isResolved = true
            }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
        }

        // 4. Everything completed — all green tags, .md has > quote resolutions
        let kickoff = seedMemo(
            title: "a16z application kickoff",
            date: daysAgo(10, hour: 16, minute: 15),
            duration: 74 * 60 + 0,
            analysisMarkdown: Self.demo_a16zKickoff
        )
        if let memo = kickoff, let analysis = memo.analysis {
            for (i, t) in analysis.openThreads.enumerated() {
                t.resolution = ["framed as the cultural shift, not the tool — clearer.",
                                "interview-first, video later. apolline lead.",
                                "named two specific labels in the draft."][safe: i] ?? "resolved."
                t.isResolved = true
            }
            for (i, d) in analysis.keyDecisions.enumerated() {
                d.resolution = ["shipped the kickoff memo internally before drafting.",
                                "deferred polish until after the first read-through.",
                                "set a hard deadline for the application: this friday."][safe: i] ?? "done."
                d.isResolved = true
            }
            for a in analysis.actionItems { a.isResolved = true }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
        }

        // 5. Summary + notes only, no items — to demo varied analysis shapes
        seedMemo(
            title: "founder coffee with maya",
            date: daysAgo(13, hour: 9, minute: 30),
            duration: 18 * 60 + 22,
            analysisMarkdown: Self.demo_founderCoffee
        )

        seedToast = "5 demo memos added — check browse + debrief"
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            await MainActor.run { seedToast = nil }
        }
    }

    @discardableResult
    private func seedMemo(
        title: String,
        date: Date,
        duration: TimeInterval,
        analysisMarkdown: String?
    ) -> Memo? {
        let memo = Memo(
            title: title,
            sourceURL: TimbrePaths.library.appendingPathComponent("demo-placeholder.m4a"),
            audioBookmark: nil,
            dateRecorded: date,
            duration: duration,
            fileSize: 0
        )
        memo.status = analysisMarkdown == nil ? .completed : .analyzed
        modelContext.insert(memo)

        if let md = analysisMarkdown {
            let parsed = AnalysisPromptBuilder.parseManualResponse(md)
            let analysis = MemoAnalysis(analysisModelUsed: "demo-seed")
            analysis.summary = parsed.summary
            analysis.detailedNotes = parsed.detailedNotes
            analysis.dateAnalyzed = .now
            analysis.isStale = false
            modelContext.insert(analysis)
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
            memo.analysis = analysis
        }

        try? modelContext.save()
        AnalysisDiskExport.writeIfPossible(memo)
        return memo
    }

    private func resetAllData() {
        // SwiftData: delete every memo, analysis, analysis item, folder.
        // SwiftData cascades from Memo through analysis -> items via the
        // model graph, but be explicit for clarity.
        if let memos = try? modelContext.fetch(FetchDescriptor<Memo>()) {
            for m in memos { modelContext.delete(m) }
        }
        if let analyses = try? modelContext.fetch(FetchDescriptor<MemoAnalysis>()) {
            for a in analyses { modelContext.delete(a) }
        }
        if let items = try? modelContext.fetch(FetchDescriptor<AnalysisItem>()) {
            for i in items { modelContext.delete(i) }
        }
        if let folders = try? modelContext.fetch(FetchDescriptor<Folder>()) {
            for f in folders { modelContext.delete(f) }
        }
        try? modelContext.save()

        // Files: wipe library/, transcripts/, analyses/
        let fm = FileManager.default
        for dir in [TimbrePaths.library, TimbrePaths.transcripts, TimbrePaths.analyses] {
            if let entries = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for url in entries { try? fm.removeItem(at: url) }
            }
        }

        seedToast = "all data deleted"
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { seedToast = nil }
        }
    }

    // MARK: - Demo analysis content

    private static let demo_y2kResearch = """
    ## SUMMARY
    apolline mapped the y2k aesthetic genealogy from late-90s win98 chrome through the dotcom optimism era. the working thesis: y2k visual culture is a delayed reaction to digital-physical liminality, not nostalgia for the period itself.

    ## NOTES
    ### genealogy
    - the period 1996-2002 produced a distinctive chrome + iridescence vocabulary that maps onto the cultural anxiety of platform shift
    - what looks "retro" to gen z is actually the first generation of consumer software design treating the screen as a 3d object

    ### why now
    - we're in a similar liminal moment (ai layer over existing apps) so the visual vocabulary rhymes
    - tools like figma + framer make the chrome aesthetic cheap to reproduce; in 1999 it required photoshop wizardry

    ## DECISIONS
    - lead the timbre aesthetic with chrome bubbles + brushed metal, not retro pixel grid
    - keep the speaker badge color palette saturated y2k blue/cyan/magenta
    - icon set should be photographic-feeling (gradients, glints) not flat

    ## ACTIONS
    - apolline: write the timbre design philosophy doc by next week
    - apolline: collect 20 reference y2k screenshots into a moodboard
    - both: review whether chrome-bubble pattern translates to the record view's mic button

    ## QUESTIONS
    - does the y2k frame survive contact with users who weren't alive in 1999?
    - is the chrome aesthetic actually load-bearing for the product story, or just a vibe?
    - how do we keep the visual language coherent when we ship dark mode?
    """

    private static let demo_designCrit = """
    ## SUMMARY
    idan walked through the timbre side panel with apolline. two big calls: actions belong at the top, not the bottom; meeting chips need to feel like first-class navigation, not metadata.

    ## NOTES
    ### action placement
    - per-card prompt buttons created visual noise — a single actions banner reads as "what can i do here"
    - the analyze affordance has to come before the content it would generate, not after

    ### chips as navigation
    - flat doc.text glyph reads as metadata; a styled chip with a clear hit target reads as interactive
    - light-blue gradient against the analysis-card white background gives enough contrast to be obviously tappable

    ## DECISIONS
    - move all per-card prompt buttons into a single actions row directly under the header
    - the meeting chip in debrief gets a chip-shaped styled background, not just an icon
    - keep the prompt + edit button colors light blue, matching decode

    ## ACTIONS
    - apolline: implement the actions banner in MemoSidePanel
    - apolline: restyle the meeting chip with the light-blue gradient capsule
    - idan: review the next build before friday

    ## QUESTIONS
    - should the meeting chip eventually surface the speaker icons too?
    - does "answer" vs "complete" need different colors, or is the placement clear enough?
    - what happens to a card when its source memo gets deleted?
    """

    private static let demo_a16zKickoff = """
    ## SUMMARY
    kickoff for the a16z application. agreed on the gatekeeper framing as the headline thesis. structured the application around three reference points: a profile interview, a video deep-dive, and a written architecture brief.

    ## NOTES
    ### framing
    - gatekeeper-as-cultural-shift is the strongest single sentence we have
    - the music supply curve discussion gives the strongest data point — finite attention, infinite supply, value moves up the stack to curation

    ### artifact strategy
    - interview is the credibility vehicle
    - video is the visceral demo
    - architecture brief is the technical proof

    ## DECISIONS
    - lead the application with the interview piece
    - defer polish on the video until the interview lands
    - target friday as the application submission deadline

    ## ACTIONS
    - apolline: write the interview outline by tuesday
    - apolline: draft the gatekeeper framing in 2-3 quotable paragraphs
    - idan: pull together the supply-shock slides from the partnership convo
    - both: review architecture brief outline thursday

    ## QUESTIONS
    - do we name specific labels as the "gatekeepers" or stay abstract?
    - is the partnership angle a distraction from the cultural framing, or the proof point?
    - what's the actual ask of the interviewer — profile or debate?
    """

    private static let demo_founderCoffee = """
    ## SUMMARY
    maya shared her experience scaling a creator-tools startup from 0 to 50k users. key insight: the founders who succeed in the creator economy aren't the ones who optimize for retention metrics, they're the ones who optimize for being talked about in private group chats.

    ## NOTES
    ### what maya did differently
    - prioritized one-on-one onboarding for the first 100 users, against vc advice
    - never used "growth hacks" — every channel was a direct conversation
    - shipped slow on purpose to make every feature feel inevitable

    ### what would scale to timbre
    - the analyze + decode pattern feels right because it mirrors how power users actually take meeting notes
    - the .md export hits the agent-native angle without us having to oversell it

    ### tactical
    - the brand voice (lowercase, terse, opinionated) is the thing
    - landing-page copy should be 80% screenshots, 20% words
    """

    private var aboutSection: some View {
        sectionCard("about") {
            HStack {
                Text("timbre")
                    .font(TimbreFont.fontBold(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text("v\(appVersion)")
                    .font(TimbreFont.font(size: 14))
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func sectionCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(TimbreFont.fontBold(size: 16))
                .foregroundStyle(Color(hex: "0088FF"))

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(hex: "40C8FF").opacity(0.25))
        )
    }

    private func saveKey() {
        keySaved = false
        keyError = nil
        do {
            if apiKey.isEmpty {
                KeychainService.delete(key: "openai-api-key")
            } else {
                try KeychainService.save(key: "openai-api-key", value: apiKey)
            }
            keySaved = true
        } catch {
            keyError = error.localizedDescription
        }
    }
}

// Tiny Array helper used by the demo-seed indexing.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
