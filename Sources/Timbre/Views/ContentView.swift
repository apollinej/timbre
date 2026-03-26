import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.dateImported, order: .reverse) private var memos: [Memo]
    @Query(sort: \Folder.sortIndex) private var folders: [Folder]
    @State private var selectedMemo: Memo?
    @State private var importer = AudioImporter()
    @State private var isTargeted = false

    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR
            sidebar
                .frame(width: 220)

            // Chrome bevel divider
            ZStack {
                Rectangle().fill(Color.black.opacity(0.3))
                HStack(spacing: 0) {
                    Rectangle().fill(Color.black.opacity(0.2)).frame(width: 1)
                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                }
            }
            .frame(width: 2)

            // DETAIL
            detail
        }
        .onDrop(of: AudioImporter.supportedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .overlay {
            if isTargeted { ImportDropZone() }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Sidebar toolbar
            HStack(spacing: 8) {
                BubbleButton(icon: "plus", size: 26, color: Color(hex: "78A8E0")) {
                    openImportPanel()
                }

                BubbleButton(icon: "folder.badge.plus", size: 26, color: Color(hex: "88B8D0")) {
                    createFolder()
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BrushedMetal(baseColor: Color(hex: "7090B8"), intensity: 0.3))
            .overlay(
                VStack {
                    Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1)
                }
            )

            // Inset memo list
            // Memo list — brushed metal with subtle inset
            ChromeInset {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(folders.sorted(by: { $0.dateCreated < $1.dateCreated })) { folder in
                            FolderSection(
                                folder: folder,
                                memos: memosInFolder(folder),
                                selectedMemo: $selectedMemo,
                                allFolders: folders,
                                modelContext: modelContext
                            )
                        }

                        let unfiled = memos.filter { $0.folder == nil }
                        ForEach(unfiled) { memo in
                            MemoRow(
                                memo: memo,
                                isSelected: selectedMemo?.id == memo.id,
                                folders: folders,
                                modelContext: modelContext
                            ) { selectedMemo = memo }
                        }

                        if memos.isEmpty {
                            VStack(spacing: 6) {
                                Text("no memos yet")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: "8898A8"))
                                Text("click + to import")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color(hex: "A0A8B8"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(3)
                }
                .background(BrushedMetal(baseColor: Color(hex: "A8B0C0"), intensity: 0.25))
            }
            .padding(6)
        }
        .background(BrushedMetal(baseColor: Color(hex: "B0B8C8"), intensity: 0.3))
    }

    // MARK: - Detail

    private var detail: some View {
        ZStack {
            // Opaque iridescent silver base
            LinearGradient(
                colors: [
                    Color(hex: "D0D4E0"),
                    Color(hex: "C4CCE0"),
                    Color(hex: "D4D0E4"),
                    Color(hex: "C8D4E8"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle shimmer
            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear,
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.white.opacity(0.15),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if let memo = selectedMemo {
                TranscriptView(memo: memo)
            } else {
                EmptyStateView(importer: importer)
            }
        }
    }

    // MARK: - Helpers

    private func createFolder() {
        let folder = Folder(name: "New Folder", sortIndex: folders.count)
        modelContext.insert(folder)
        try? modelContext.save()
    }

    private func memosInFolder(_ folder: Folder) -> [Memo] {
        folder.memos.sorted { $0.dateImported > $1.dateImported }
    }

    private func openImportPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = AudioImporter.supportedTypes
        if let p = AudioImporter.voiceMemosPath { panel.directoryURL = p }
        guard panel.runModal() == .OK else { return }
        Task {
            let imported = await importer.importFiles(panel.urls, into: modelContext)
            if let first = imported.first { selectedMemo = first }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                Task { @MainActor in
                    let imported = await importer.importFiles([url], into: modelContext)
                    if let first = imported.first { selectedMemo = first }
                }
            }
        }
    }
}

// MARK: - Folder Section

struct FolderSection: View {
    let folder: Folder
    let memos: [Memo]
    @Binding var selectedMemo: Memo?
    let allFolders: [Folder]
    let modelContext: ModelContext
    @State private var isExpanded = true
    @State private var renaming = false

    var body: some View {
        VStack(spacing: 0) {
            Button { isExpanded.toggle() } label: {
                HStack(spacing: 5) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(hex: "6878A0"))
                        .frame(width: 10)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "5080C0"))

                    Text(folder.name.lowercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "4868A0"))

                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Rename\u{2026}") { renaming = true }
                Divider()
                Button("Delete", role: .destructive) {
                    for m in folder.memos { m.folder = nil }
                    modelContext.delete(folder)
                    try? modelContext.save()
                }
            }

            if isExpanded {
                ForEach(memos) { memo in
                    MemoRow(
                        memo: memo,
                        isSelected: selectedMemo?.id == memo.id,
                        folders: allFolders,
                        modelContext: modelContext
                    ) { selectedMemo = memo }
                    .padding(.leading, 12)
                }
            }
        }
        .sheet(isPresented: $renaming) {
            RetroRenameSheet(title: "rename folder", currentName: folder.name) { newName in
                folder.name = newName
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Memo Row

struct MemoRow: View {
    let memo: Memo
    let isSelected: Bool
    let folders: [Folder]
    let modelContext: ModelContext
    let onSelect: () -> Void
    @State private var renaming = false

    var body: some View {
        Button { onSelect() } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(memo.title)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white : Color(hex: "3A4860"))
                    .lineLimit(1)

                HStack {
                    Text(memo.formattedDuration)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color(hex: "7888A0"))
                    Spacer()
                    RetroStatusBadge(status: memo.status)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "4890D0"), Color(hex: "3070B0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename\u{2026}") { renaming = true }
            if !folders.isEmpty {
                Menu("Move to Folder") {
                    ForEach(folders.sorted(by: { $0.dateCreated < $1.dateCreated })) { folder in
                        Button(folder.name) {
                            memo.folder = folder
                            try? modelContext.save()
                        }
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                modelContext.delete(memo)
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $renaming) {
            RetroRenameSheet(title: "rename memo", currentName: memo.title) { newName in
                memo.title = newName
                try? modelContext.save()
            }
        }
    }
}
