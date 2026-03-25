import AppKit
import SwiftUI

struct ExportButton: View {
    let memo: Memo

    var body: some View {
        Menu {
            ForEach(ExportFormat.allCases) { format in
                Button(format.displayName) {
                    exportTranscript(format: format)
                }
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(memo.transcript == nil)
    }

    private func exportTranscript(format: ExportFormat) {
        guard let transcript = memo.transcript else { return }

        let content = ExportService.export(
            transcript: transcript,
            memoTitle: memo.title,
            duration: memo.duration,
            format: format
        )

        let panel = NSSavePanel()
        panel.title = "Export Transcript"
        panel.nameFieldStringValue = "\(memo.title).\(format.fileExtension)"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
