import SwiftUI
import SwiftData

@main
struct TimbreApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Memo.self, Transcript.self, Segment.self, Speaker.self])

        Settings {
            SettingsView()
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.dateImported, order: .reverse) private var memos: [Memo]
    @State private var selectedMemo: Memo?
    @State private var isTargeted = false

    var body: some View {
        NavigationSplitView {
            LibraryView(memos: memos, selectedMemo: $selectedMemo)
        } detail: {
            if let memo = selectedMemo {
                TranscriptView(memo: memo)
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onDrop(of: [.audio, .fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .overlay {
            if isTargeted {
                ImportDropZone()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    importFiles()
                } label: {
                    Label("Import", systemImage: "plus")
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }

    private func importFiles() {
        Task {
            let importer = AudioImporter(modelContext: modelContext)
            await importer.showImportPanel()
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        let importer = AudioImporter(modelContext: modelContext)
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                Task { @MainActor in
                    await importer.importFile(at: url)
                }
            }
        }
    }
}
