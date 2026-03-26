import Foundation
import SwiftData

/// Writes `ExportService` plain-text transcripts to `~/Desktop/.../timbre/transcripts/<memo-id>.txt`.
enum TranscriptDiskExport {
    private static let fm = FileManager.default

    static func fileURL(for memoId: UUID) -> URL {
        TimbrePaths.transcripts.appendingPathComponent("\(memoId.uuidString).txt", isDirectory: false)
    }

    static func removeFile(for memoId: UUID) {
        let url = fileURL(for: memoId)
        if fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }

    /// Writes or deletes the on-disk mirror for one memo.
    static func writeMemoTranscriptIfNeeded(_ memo: Memo) throws {
        try TimbrePaths.prepareStorageDirectories()

        let url = fileURL(for: memo.id)
        guard memo.status == .completed, memo.transcript != nil else {
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
            return
        }

        guard let body = ExportService.export(memo: memo, format: .plainText) else { return }
        try body.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Refreshes every completed memo (e.g. after migration or batch rename).
    @MainActor
    static func syncAllMemos(modelContext: ModelContext) {
        try? TimbrePaths.prepareStorageDirectories()
        let descriptor = FetchDescriptor<Memo>()
        guard let memos = try? modelContext.fetch(descriptor) else { return }
        let validIds = Set(memos.map(\.id))
        for memo in memos {
            try? writeMemoTranscriptIfNeeded(memo)
        }
        pruneOrphanTranscriptFiles(validMemoIds: validIds)
    }

    private static func pruneOrphanTranscriptFiles(validMemoIds: Set<UUID>) {
        guard let names = try? fm.contentsOfDirectory(atPath: TimbrePaths.transcripts.path) else { return }
        for name in names where name.hasSuffix(".txt") {
            let base = (name as NSString).deletingPathExtension
            guard let id = UUID(uuidString: base), !validMemoIds.contains(id) else { continue }
            try? fm.removeItem(at: TimbrePaths.transcripts.appendingPathComponent(name))
        }
    }
}
