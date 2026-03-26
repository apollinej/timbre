import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
final class AudioImporter {
    var isImporting = false
    var lastError: String?

    static let voiceMemosPath: URL? = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home
            .appendingPathComponent("Library/Group Containers")
            .appendingPathComponent("group.com.apple.VoiceMemos.shared")
            .appendingPathComponent("Recordings")
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }()

    static let supportedTypes: [UTType] = [
        .audio,
        .mpeg4Audio,
        .wav,
        .mp3,
        UTType(filenameExtension: "flac")!,
        .aiff,
    ]

    func importFiles(
        _ urls: [URL],
        into context: ModelContext
    ) async -> [Memo] {
        isImporting = true
        lastError = nil
        defer { isImporting = false }

        var imported: [Memo] = []

        for url in urls {
            guard AudioFileHelper.isSupported(url) else {
                lastError = "Unsupported format: \(url.pathExtension)"
                continue
            }

            do {
                let memo = try await importSingleFile(url, into: context)
                imported.append(memo)
            } catch {
                lastError = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }

        return imported
    }

    private func importSingleFile(
        _ url: URL,
        into context: ModelContext
    ) async throws -> Memo {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let metadata = try await AudioFileHelper.metadata(for: url)

        // Create security-scoped bookmark for future access
        let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let title = url.deletingPathExtension().lastPathComponent

        let memo = Memo(
            title: title,
            sourceURL: url,
            audioBookmark: bookmark,
            dateRecorded: metadata.creationDate,
            duration: metadata.duration,
            fileSize: metadata.fileSize
        )

        context.insert(memo)
        try context.save()

        return memo
    }
}
