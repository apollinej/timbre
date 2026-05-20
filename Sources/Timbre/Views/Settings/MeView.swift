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

        // 1. Un-analyzed solo voice memo
        let bus = seedMemo(
            title: "voice memo from the bus",
            date: daysAgo(1, hour: 18, minute: 47),
            duration: 4 * 60 + 22,
            analysisMarkdown: nil
        )
        if let m = bus { seedTranscript(memo: m, names: ["me"], lines: [
            (0, 0, "okay so the thing i keep coming back to is that the ep needs a name that doesn't sound like every other ep name from this year."),
            (0, 14, "what if we just lean into the bus thing. like the whole record is voice memos i sent myself on public transit."),
        ]) }

        // 2. Phone call w/ collaborator, fresh analysis
        let phoneKai = seedMemo(
            title: "phone call with kai",
            date: daysAgo(4, hour: 21, minute: 12),
            duration: 27 * 60 + 38,
            analysisMarkdown: Self.demo_phoneKai
        )
        if let m = phoneKai { seedTranscript(memo: m, names: ["me", "kai"], lines: [
            (0, 0, "okay so the cover. you wanna go darker, right?"),
            (1, 4, "yeah. it just reads more cohesive across the track sequence. especially track 3 into 4."),
            (0, 9, "i hear that but the iridescent thing is what ties it to the live show. the lights."),
            (1, 16, "okay why don't we just mock both and sit with it for a week."),
        ]) }

        // 3. Partial resolutions — studio chat
        let studio = seedMemo(
            title: "studio chat with noor",
            date: daysAgo(7, hour: 14, minute: 0),
            duration: 41 * 60 + 18,
            analysisMarkdown: Self.demo_studioNoor
        )
        if let memo = studio, let analysis = memo.analysis {
            if let t = analysis.openThreads.first {
                t.resolution = "yeah — we're keeping the original sample. it's the whole reason the song works."
                t.isResolved = true
            }
            if let d = analysis.keyDecisions.first {
                d.resolution = "vinyl first, streaming follows. confirmed with the pressing plant friday."
                d.isResolved = true
            }
            if let a = analysis.actionItems.first { a.isResolved = true }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
            seedTranscript(memo: memo, names: ["me", "noor"], lines: [
                (0, 0, "the sample is the whole point of the song, we can't lose it."),
                (1, 5, "i agree but we have to figure out the clearance situation first."),
                (0, 11, "okay let's call the publisher monday."),
            ])
        }

        // 4. Everything resolved — weekend trip planning
        let trip = seedMemo(
            title: "weekend trip planning",
            date: daysAgo(10, hour: 19, minute: 30),
            duration: 36 * 60 + 5,
            analysisMarkdown: Self.demo_tripPlanning
        )
        if let memo = trip, let analysis = memo.analysis {
            let qRes = [
                "we're skipping the museum — group consensus, too packed on saturday.",
                "lou's friend has the apartment, so yes free for both nights.",
                "decided no — we're keeping it loose. no formal dinner plan."
            ]
            let dRes = [
                "drive — split gas three ways, leaves at 9am friday.",
                "stay at lou's friend's place fri + sat.",
                "saturday night: walk around the neighborhood, find food on the fly."
            ]
            for (i, t) in analysis.openThreads.enumerated() {
                t.resolution = qRes[safe: i] ?? "resolved."
                t.isResolved = true
            }
            for (i, d) in analysis.keyDecisions.enumerated() {
                d.resolution = dRes[safe: i] ?? "done."
                d.isResolved = true
            }
            for a in analysis.actionItems { a.isResolved = true }
            try? modelContext.save()
            AnalysisDiskExport.writeIfPossible(memo)
            seedTranscript(memo: memo, names: ["me", "lou", "vee"], lines: [
                (0, 0, "okay so are we driving or training?"),
                (1, 4, "driving is way easier with all the stuff."),
                (2, 8, "and we can stop in pittsburgh on the way."),
                (0, 13, "okay drive it is. who's renting?"),
            ])
        }

        // 5. Summary + notes only — 3am voice note
        let threeAm = seedMemo(
            title: "3am thought log",
            date: daysAgo(13, hour: 3, minute: 14),
            duration: 6 * 60 + 41,
            analysisMarkdown: Self.demo_threeAm
        )
        if let m = threeAm { seedTranscript(memo: m, names: ["me"], lines: [
            (0, 0, "okay it's 3am and i had this thought that i don't want to forget."),
            (0, 6, "what if the album sequencing was based on what time of day each song was made."),
        ]) }

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

    /// Seed a minimal transcript with N speakers (named via `names`) and
    /// a few segments (speakerIndex, startTime, text). Just enough to make
    /// the speaker chips appear in Browse cards + side panel.
    private func seedTranscript(
        memo: Memo,
        names: [String],
        lines: [(Int, TimeInterval, String)]
    ) {
        let palette = ["0088FF", "00C890", "FF7AB6", "FFB347", "B27AFF"]
        let speakers: [Speaker] = names.enumerated().map { (idx, name) in
            let s = Speaker(
                label: "Speaker \(idx + 1)",
                displayName: name,
                colorHex: palette[idx % palette.count]
            )
            modelContext.insert(s)
            return s
        }
        let transcript = Transcript(modelUsed: "demo-seed", language: "en")
        modelContext.insert(transcript)
        for (speakerIdx, start, text) in lines {
            let seg = Segment(
                text: text,
                startTime: start,
                endTime: start + 3,
                speaker: speakers[safe: speakerIdx]
            )
            modelContext.insert(seg)
            transcript.segments.append(seg)
        }
        memo.transcript = transcript
        try? modelContext.save()
        AnalysisDiskExport.writeIfPossible(memo)
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

    private static let demo_phoneKai = """
    ## SUMMARY
    long phone call with kai about the ep cover. they want darker, i want iridescent. landed on mocking both and sitting with them for a week before deciding. tied to the bigger question of whether the cover should read at vinyl scale or just digital.

    ## NOTES
    ### the visual disagreement
    - kai's argument: darker palette reads more cohesive across the track sequence, especially the transition into track 3
    - my pull: iridescent ties the cover back to the live show lighting design

    ### what we landed on
    - both of us mock our direction
    - sit with both for a week, no committing on the call
    - revisit next friday

    ## DECISIONS
    - mock both palettes before committing
    - defer the final cover call to next friday
    - cover decision blocks the merch order — flag for the press cycle

    ## ACTIONS
    - me: draft the iridescent version by sunday
    - kai: pull the dark-palette moodboard
    - me: sketch how the cover crops for the spotify canvas

    ## QUESTIONS
    - does the cover need to read at vinyl scale, or just digital first?
    - should we test on actual screens with people before committing?
    - is the cover typography locked or still open to revisit?
    """

    private static let demo_studioNoor = """
    ## SUMMARY
    studio session with noor on the sample question. we were going to swap the original sample because of clearance concerns, but talked through it and agreed the song doesn't work without it. plan is to call the publisher monday and figure out the actual licensing path.

    ## NOTES
    ### the sample debate
    - noor's worry: clearance might be expensive or blocked entirely
    - my position: it's the whole emotional core of the song. song doesn't exist without it.
    - we both agreed once we listened back to a version without it — it just doesn't land

    ### release format
    - vinyl first feels right for this record specifically
    - streaming can follow a week later, gives the record a moment

    ## DECISIONS
    - keep the original sample, pursue clearance
    - release vinyl first, streaming follows
    - cancel the alt-version tracking session — not needed

    ## ACTIONS
    - me: call the publisher monday morning
    - noor: pull the sample's metadata + previous use cases for the call
    - me: confirm vinyl pressing plant slot for the new timeline

    ## QUESTIONS
    - if clearance fails, do we shelve the song or hire a re-interpolator?
    - should we tease the song before clearance is locked, or wait?
    - what's the right vinyl-only window — a week, two, a month?
    """

    private static let demo_tripPlanning = """
    ## SUMMARY
    trip planning call with lou and vee for the long weekend. settled on driving instead of training, staying at lou's friend's apartment, and keeping saturday loose. the museum got cut, the formal dinner got cut, and we agreed that's a feature not a bug.

    ## NOTES
    ### transit
    - driving wins because of all the gear we want to bring
    - vee suggested stopping in pittsburgh on the way — small detour, worth it

    ### the loose-saturday philosophy
    - lou pushed for an unstructured saturday after the last trip got over-planned
    - vee was the dissent — wanted at least one anchor reservation
    - we compromised: no plans saturday, but friday dinner is locked

    ## DECISIONS
    - drive, not train — leaving 9am friday
    - stay at lou's friend's apartment for both nights
    - keep saturday completely unplanned — walk around, find food on the fly

    ## ACTIONS
    - lou: confirm the apartment friday morning
    - me: book the friday dinner spot
    - vee: figure out the pittsburgh stop — where, how long

    ## QUESTIONS
    - do we want to do the museum or skip it?
    - is the apartment free both nights or just one?
    - should we book a formal dinner saturday or stay loose?
    """

    private static let demo_threeAm = """
    ## SUMMARY
    3am voice memo. one idea: sequence the album by the time of day each song was made rather than by mood or energy. the night songs cluster at the start, sunrise transitions to the daytime songs in the middle, evening songs land at the end. could either be a meta-concept the listener doesn't need to know, or part of the press story.

    ## NOTES
    ### the time-of-day sequence
    - night tracks 1-3 (made between 1am-5am)
    - dawn track 4 (the field recording is literally a sunrise)
    - daytime tracks 5-8 (made afternoon or evening)
    - night again for the closer — full loop

    ### whether to surface this
    - the cleanest version is to never tell anyone and let the structure work in the background
    - the press-friendly version is to lead with it — it's a clean narrative hook

    ### what it costs us
    - track 6 might need to move because of energy reasons even if it's daytime
    - the time-of-day rule can't be a hard constraint; it should be a strong default

    ### feel of it
    - if it works, it'll feel like the album breathes
    - if it doesn't work, no one will know we tried
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
