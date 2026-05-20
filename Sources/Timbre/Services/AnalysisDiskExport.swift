import Foundation
import SwiftData

/// Writes every memo's analysis as a `.md` file on disk so external
/// editors and agents can read and modify it directly.
///
/// File layout: `<storage root>/analyses/<slug>__<short-id>.md` —
/// slug is human-readable for browsing in Finder, short-id is appended
/// to avoid collisions across memos with the same title.
///
/// Format matches `AnalysisPromptBuilder.renderAnalysisMarkdown` plus
/// a front-matter block so external tools can map back to the memo:
///
///     ---
///     timbre-memo-id: 1A2B3C…
///     title: a16z things we wanna say
///     date: 2026-05-17T14:00:00Z
///     duration: 937
///     model: openai-gpt-4o
///     analyzed: 2026-05-19T16:00:00Z
///     ---
///
///     ## SUMMARY
///     …
///
/// Resolved threads/actions/decisions are rendered as `- [x] …` so
/// the file remains valid GitHub-flavored task-list markdown.
enum AnalysisDiskExport {

    static func write(_ memo: Memo) throws {
        try TimbrePaths.prepareStorageDirectories()
        let url = fileURL(for: memo)
        let body = render(memo)
        try body.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Best-effort write — swallows errors. Used from UI hooks where
    /// a failed disk write shouldn't block the SwiftData save.
    static func writeIfPossible(_ memo: Memo) {
        do {
            try write(memo)
        } catch {
            // Surface to console for debugging but don't fail the UI flow.
            #if DEBUG
            print("AnalysisDiskExport: failed to write \(memo.title): \(error)")
            #endif
        }
    }

    static func remove(memoID: UUID, title: String) {
        let url = fileURL(memoID: memoID, title: title)
        try? FileManager.default.removeItem(at: url)
    }

    /// Backfill: write a `.md` for every memo that has analysis but
    /// no file on disk yet. Also removes orphaned legacy-format files
    /// (e.g. left over from the previous `<slug>__<id>.md` scheme)
    /// so the analyses/ directory mirrors the current memo set.
    static func syncAll(modelContext: ModelContext) {
        do {
            try TimbrePaths.prepareStorageDirectories()
            let memos = try modelContext.fetch(FetchDescriptor<Memo>())
            var expected: Set<String> = []
            for memo in memos where memo.analysis != nil {
                writeIfPossible(memo)
                expected.insert(fileURL(for: memo).lastPathComponent)
            }

            // Sweep orphans (legacy naming, deleted memos, etc.)
            let fm = FileManager.default
            if let entries = try? fm.contentsOfDirectory(
                at: TimbrePaths.analyses,
                includingPropertiesForKeys: nil
            ) {
                for url in entries where url.pathExtension == "md" {
                    if !expected.contains(url.lastPathComponent) {
                        try? fm.removeItem(at: url)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("AnalysisDiskExport.syncAll fetch failed: \(error)")
            #endif
        }
    }

    // MARK: - Rendering

    private static func render(_ memo: Memo) -> String {
        var lines: [String] = []
        lines.append("---")
        lines.append("timbre-memo-id: \(memo.id.uuidString)")
        lines.append("title: \(memo.title)")
        let isoFormatter = ISO8601DateFormatter()
        let recordedDate = memo.dateRecorded ?? memo.dateImported
        lines.append("date: \(isoFormatter.string(from: recordedDate))")
        lines.append("duration: \(Int(memo.duration))")
        if let model = memo.analysis?.analysisModelUsed {
            lines.append("model: \(model)")
        }
        if let analyzed = memo.analysis?.dateAnalyzed {
            lines.append("analyzed: \(isoFormatter.string(from: analyzed))")
        }
        lines.append("---")
        lines.append("")

        guard let analysis = memo.analysis else {
            lines.append("_no analysis yet — open this memo in timbre and click prompt_")
            return lines.joined(separator: "\n")
        }

        if let s = analysis.summary, !s.isEmpty {
            lines.append("## SUMMARY")
            lines.append(s)
            lines.append("")
        }
        if !analysis.keyDecisions.isEmpty {
            lines.append("## DECISIONS")
            for item in analysis.keyDecisions {
                lines.append(renderBullet(item))
            }
            lines.append("")
        }
        if !analysis.actionItems.isEmpty {
            lines.append("## ACTIONS")
            for item in analysis.actionItems {
                lines.append(renderBullet(item))
            }
            lines.append("")
        }
        if !analysis.openThreads.isEmpty {
            lines.append("## QUESTIONS")
            for item in analysis.openThreads {
                lines.append(renderBullet(item))
            }
            lines.append("")
        }
        if let n = analysis.detailedNotes, !n.isEmpty {
            lines.append("## NOTES")
            lines.append(n)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func renderBullet(_ item: AnalysisItem) -> String {
        var line = item.isResolved ? "- [x] \(item.text)" : "- [ ] \(item.text)"
        if let res = item.resolution?.trimmingCharacters(in: .whitespacesAndNewlines),
           !res.isEmpty {
            // GitHub-flavored markdown nested blockquote — readable in Obsidian
            // and survives round-trips through any GFM editor.
            let quoted = res.components(separatedBy: .newlines)
                .map { "  > \($0)" }
                .joined(separator: "\n")
            line.append("\n\(quoted)")
        }
        return line
    }

    // MARK: - Paths

    private static func fileURL(for memo: Memo) -> URL {
        fileURL(date: memo.dateRecorded ?? memo.dateImported, title: memo.title)
    }

    private static func fileURL(memoID: UUID, title: String) -> URL {
        // Legacy callers that only know id+title — best effort.
        fileURL(date: .now, title: title)
    }

    /// `YYYY-MM-DD_<2-4-word-slug>.md` — date-sortable, human-readable,
    /// safe in Finder / Obsidian / agents.
    static func fileURL(date: Date, title: String) -> URL {
        let datePrefix = isoDateFormatter.string(from: date)
        let slug = shortSlug(title)
        let name = "\(datePrefix)_\(slug).md"
        return TimbrePaths.analyses.appendingPathComponent(name)
    }

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    /// 2-4 lowercased words from the title, hyphen-joined, with
    /// dates/years stripped (since the filename already has the date).
    static func shortSlug(_ title: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: " "))
        let lowered = title.lowercased()
        var cleaned = ""
        for scalar in lowered.unicodeScalars {
            cleaned.append(allowed.contains(scalar) ? Character(scalar) : " ")
        }
        let stopwords: Set<String> = [
            "the", "a", "an", "of", "to", "for", "with", "and", "or", "in", "on", "at",
            "we", "i", "you", "is", "are", "was", "were", "be", "as",
            "pt", "part", "vol", "ep",
        ]
        let words = cleaned
            .split(separator: " ")
            .map(String.init)
            .filter { word in
                guard !word.isEmpty else { return false }
                // Drop pure numbers (likely dates / part numbers like "20", "2026", "1")
                if word.allSatisfy({ $0.isNumber }) { return false }
                if stopwords.contains(word) { return false }
                return true
            }
        let picked = Array(words.prefix(3))
        let slug = picked.joined(separator: "-")
        return slug.isEmpty ? "untitled" : slug
    }
}
