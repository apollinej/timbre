import AppKit
import AVFoundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class AudioImporter {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func showImportPanel() async {
        let panel = NSOpenPanel()
        panel.title = "Import Audio"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .wav, .mp3, .aiff]

        // Try to start in Voice Memos folder
        let voiceMemosPath = NSHomeDirectory() +
            "/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings"
        if FileManager.default.fileExists(atPath: voiceMemosPath) {
            panel.directoryURL = URL(fileURLWithPath: voiceMemosPath)
        }

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
        guard response == .OK else { return }

        for url in panel.urls {
            await importFile(at: url)
        }
    }

    func importFile(at url: URL) async {
        guard AudioUtilities.isSupported(url) else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        guard let metadata = try? await AudioUtilities.metadata(for: url) else { return }

        let fileSize = (try? FileManager.default.attributesOfItem(
            atPath: url.path
        )[.size] as? Int64) ?? 0

        let title = url.deletingPathExtension().lastPathComponent

        let memo = Memo(
            title: title,
            sourceURL: url,
            audioBookmark: bookmark,
            dateRecorded: metadata.dateRecorded,
            duration: metadata.duration,
            fileSize: fileSize
        )

        modelContext.insert(memo)
        try? modelContext.save()
    }
}
