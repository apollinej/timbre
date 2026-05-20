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
    /// no file on disk yet. Idempotent — overwrites stale files.
    static func syncAll(modelContext: ModelContext) {
        do {
            let memos = try modelContext.fetch(FetchDescriptor<Memo>())
            for memo in memos where memo.analysis != nil {
                writeIfPossible(memo)
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
        item.isResolved ? "- [x] \(item.text)" : "- [ ] \(item.text)"
    }

    // MARK: - Paths

    private static func fileURL(for memo: Memo) -> URL {
        fileURL(memoID: memo.id, title: memo.title)
    }

    private static func fileURL(memoID: UUID, title: String) -> URL {
        let slug = slugify(title)
        let shortID = String(memoID.uuidString.prefix(8)).lowercased()
        let name = "\(slug)__\(shortID).md"
        return TimbrePaths.analyses.appendingPathComponent(name)
    }

    private static func slugify(_ title: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        let lowered = title.lowercased()
        var out = ""
        var lastWasDash = false
        for scalar in lowered.unicodeScalars {
            if allowed.contains(scalar) {
                out.append(Character(scalar))
                lastWasDash = false
            } else if !lastWasDash {
                out.append("-")
                lastWasDash = true
            }
        }
        let trimmed = out.trimmingCharacters(in: .init(charactersIn: "-"))
        return trimmed.isEmpty ? "untitled" : String(trimmed.prefix(60))
    }
}
