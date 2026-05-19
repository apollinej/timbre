import AppKit
import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
final class AudioImporter {
    var isImporting = false
    var lastError: String?

    /// Show the system file picker pre-pointed at Apple's Voice Memos folder
    /// and return the URLs the user selected. Empty array if canceled.
    @MainActor
    static func presentImportPanel() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = AudioImporter.supportedTypes
        if let p = AudioImporter.voiceMemosPath { panel.directoryURL = p }
        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }

    static let voiceMemosPath: URL? = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home
            .appendingPathComponent("Library/Group Containers")
            .appendingPathComponent("group.com.apple.VoiceMemos.shared")
            .appendingPathComponent("Recordings")
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }()

    static let supportedTypes: [UTType] = {
        var types: [UTType] = [
            .audio,
            .mpeg4Audio,
            .mpeg4Movie,
            .movie,
            .wav,
            .mp3,
            .aiff,
        ]
        if let aac = UTType(filenameExtension: "aac") { types.append(aac) }
        if let flac = UTType(filenameExtension: "flac") { types.append(flac) }
        if let m4p = UTType(filenameExtension: "m4p") { types.append(m4p) }
        if let aif = UTType(filenameExtension: "aif") { types.append(aif) }
        if let aifc = UTType(filenameExtension: "aifc") { types.append(aifc) }
        return types
    }()

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
                let ext = url.pathExtension.isEmpty ? "(no extension)" : ".\(url.pathExtension)"
                lastError = "Unsupported format \(ext). Try m4a, mp3, wav, aiff, flac, or mp4 audio."
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

        try TimbrePaths.prepareStorageDirectories()

        let rawExt = url.pathExtension.lowercased()
        let ext: String
        if rawExt.isEmpty {
            ext = "m4a"
        } else if AudioFileHelper.supportedExtensions.contains(rawExt) {
            ext = rawExt
        } else {
            ext = "m4a"
        }
        let dest = TimbrePaths.library.appendingPathComponent("\(UUID().uuidString).\(ext)")

        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.copyItem(at: url, to: dest)

        let bookmark = try? dest.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let title = url.deletingPathExtension().lastPathComponent

        let memo = Memo(
            title: title,
            sourceURL: dest,
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
