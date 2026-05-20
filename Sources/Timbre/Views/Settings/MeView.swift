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
            title: "tuesday standup",
            date: daysAgo(1, hour: 9, minute: 30),
            duration: 18 * 60 + 22,
            analysisMarkdown: nil
        )

        // 2. Full analysis, no resolutions yet — to demo fresh Debrief items
        seedMemo(
            title: "product planning",
            date: daysAgo(5, hour: 15, minute: 0),
            duration: 47 * 60 + 12,
            analysisMarkdown: Self.demo_productPlanning
        )

        // 3. Partial resolutions — some answered, some pending
        let review = seedMemo(
            title: "design review",
            date: daysAgo(8, hour: 11, minute: 0),
            duration: 32 * 60 + 30,
            analysisMarkdown: Self.demo_designReview
        )
        if let memo = review, let analysis = memo.analysis {
            if let t = analysis.openThreads.first {
                t.resolution = "decided the simpler layout reads better — shipped friday with no regressions."
                t.isResolved = true
            }
            if let d = analysis.keyDecisions.first {
                d.resolution = "rolled out behind the new-ui feature flag, off by default."
                d.isResolved = true
            }
            if let a = analysis.actionItems.first {
                a.isResolved = true
            }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
        }

        // 4. Everything completed — all green tags, .md has > quote resolutions
        let kickoff = seedMemo(
            title: "quarterly kickoff",
            date: daysAgo(10, hour: 16, minute: 15),
            duration: 54 * 60 + 0,
            analysisMarkdown: Self.demo_quarterlyKickoff
        )
        if let memo = kickoff, let analysis = memo.analysis {
            for (i, t) in analysis.openThreads.enumerated() {
                t.resolution = ["agreed to scope down to two pillars instead of four.",
                                "decided to start with onboarding before the retention work.",
                                "no — we'll publish the roadmap externally after the launch."][safe: i] ?? "resolved."
                t.isResolved = true
            }
            for (i, d) in analysis.keyDecisions.enumerated() {
                d.resolution = ["shared the kickoff doc with the team before friday.",
                                "deferred the rebrand until after the next milestone.",
                                "set a hard deadline for the launch: end of next month."][safe: i] ?? "done."
                d.isResolved = true
            }
            for a in analysis.actionItems { a.isResolved = true }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
        }

        // 5. Summary + notes only, no items — to demo varied analysis shapes
        seedMemo(
            title: "1:1 with manager",
            date: daysAgo(13, hour: 14, minute: 0),
            duration: 22 * 60 + 8,
            analysisMarkdown: Self.demo_oneOnOne
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

    // MARK: - Demo analysis content (fictional — used for screenshots / first-run demo)

    private static let demo_productPlanning = """
    ## SUMMARY
    alex and sam walked through the q3 roadmap. agreed to scope down to two pillars instead of four. main risk: the migration work blocks every other workstream until the schema is stable.

    ## NOTES
    ### scope
    - dropped the analytics dashboard and the API rewrite from q3 — both move to q4
    - keeping the migration + the in-app onboarding revamp as the two pillars

    ### sequencing
    - migration first because everything downstream depends on the new schema
    - onboarding starts as soon as the migration is in staging — no need to wait for full rollout

    ## DECISIONS
    - cut the q3 roadmap from four pillars to two
    - ship the migration before any new feature work touches the affected models
    - target the onboarding revamp for the second half of q3

    ## ACTIONS
    - alex: write the migration risk doc by wednesday
    - sam: line up two test customers for early onboarding feedback
    - both: review the cut q3 items against the q4 plan next monday

    ## QUESTIONS
    - do we communicate the scope cut externally or just internally?
    - is the onboarding revamp blocked on the design system update or independent?
    - how do we measure success on the migration beyond "it shipped"?
    """

    private static let demo_designReview = """
    ## SUMMARY
    jamie walked the team through the new settings flow. two big calls: the empty state needs more guidance, and the destructive actions should live behind a confirmation, not inline.

    ## NOTES
    ### empty state
    - users land on the page with no clear next step — needs a one-liner + a primary action
    - the illustration is great but the copy reads like marketing, not instruction

    ### destructive actions
    - inline delete buttons create accidental clicks
    - move to a "danger zone" section at the bottom with a confirmation modal

    ## DECISIONS
    - add a primary call-to-action to the empty state with copy focused on "what to do next"
    - move all destructive actions to a separate danger zone with confirmation
    - keep the illustration but tighten the supporting copy

    ## ACTIONS
    - jamie: ship the empty-state copy update by thursday
    - alex: implement the danger-zone confirmation pattern
    - sam: write the post-launch user-feedback survey

    ## QUESTIONS
    - should the confirmation modal require typing the resource name?
    - does the empty state need to differ by user type, or stay one-size-fits-all?
    - is the illustration still the right tone for the new copy?
    """

    private static let demo_quarterlyKickoff = """
    ## SUMMARY
    quarterly kickoff. team aligned on three priorities for the next quarter: ship the new onboarding, double down on activation, and start scoping the integration platform. agreed to publish the roadmap publicly after the first milestone lands.

    ## NOTES
    ### priorities
    - onboarding revamp is priority one — every other metric depends on it
    - activation is priority two — clear north-star metric, owned by the growth team
    - integrations platform is priority three — scope this quarter, build next

    ### communication
    - internal kickoff doc goes out this week
    - external roadmap publishes after onboarding ships

    ## DECISIONS
    - scope down to three priorities for the quarter
    - start with onboarding before any activation work
    - publish the roadmap externally after the launch, not before

    ## ACTIONS
    - alex: write the quarterly kickoff doc by friday
    - sam: scope the integrations platform with two engineers
    - jamie: draft the external roadmap copy for review next week
    - both leads: weekly check-in every monday until launch

    ## QUESTIONS
    - do we scope to two pillars or three? team felt strongly about cutting one.
    - should we start with onboarding or activation? both have customer-validated demand.
    - publish the roadmap externally now, or wait for the first milestone?
    """

    private static let demo_oneOnOne = """
    ## SUMMARY
    weekly 1:1 with the manager. mostly a check-in on the migration project and a discussion about what "senior-level" work looks like in the next promo cycle. takeaway: take on one cross-team initiative this quarter to round out the case.

    ## NOTES
    ### migration progress
    - on track for the original timeline despite the schema scope creep
    - the test customer feedback has been more positive than expected — they like the new constraints

    ### career growth
    - the next promo cycle weighs cross-team impact heavily
    - good candidates: lead the integrations scoping, mentor a junior on the onboarding work, or write the post-launch retro

    ### tactical
    - blocked on review cycles for two of the migration PRs — manager will follow up
    - low-pri but useful: rewrite the team's onboarding doc since the original is stale
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
