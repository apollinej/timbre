import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.dateImported, order: .reverse) private var memos: [Memo]
    @Query(sort: \Folder.sortIndex) private var folders: [Folder]
    @State private var selectedMemo: Memo?
    @State private var importer = AudioImporter()
    @State private var isTargeted = false
    /// Present rename UI from the root so sheets work reliably (not from `LazyVStack` rows).
    @State private var memoPendingRename: Memo?
    @State private var folderPendingRename: Folder?
    @State private var didSyncTranscriptExports = false
    @State private var importErrorMessage: String?
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 280)

            ZStack {
                Rectangle().fill(Color(hex: "0068A0").opacity(0.35))
                HStack(spacing: 0) {
                    Rectangle().fill(Color(hex: "004060").opacity(0.35)).frame(width: 1)
                    Rectangle().fill(Color.white.opacity(0.55)).frame(width: 1)
                }
            }
            .frame(width: 2)

            detail
        }
        .onDrop(of: AudioImporter.supportedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .overlay {
            if isTargeted { ImportDropZone() }
        }
        .sheet(item: $memoPendingRename) { memo in
            RetroRenameSheet(title: "rename memo", currentName: memo.title) { newName in
                memo.title = newName
                try? modelContext.save()
                try? TranscriptDiskExport.writeMemoTranscriptIfNeeded(memo)
            }
        }
        .sheet(item: $folderPendingRename) { folder in
            RetroRenameSheet(title: "rename folder", currentName: folder.name) { newName in
                folder.name = newName
                try? modelContext.save()
            }
        }
        .onAppear {
            guard !didSyncTranscriptExports else { return }
            didSyncTranscriptExports = true
            TranscriptDiskExport.syncAllMemos(modelContext: modelContext)
        }
        .alert("import failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("ok", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                BubbleButton(icon: "plus", size: 32, color: Color(hex: "0088FF")) {
                    openImportPanel()
                }

                BubbleButton(icon: "folder.badge.plus", size: 32, color: Color(hex: "00D8A0")) {
                    createFolder()
                }

                Spacer()

                BubbleButton(icon: "gearshape.fill", size: 28, color: Color(hex: "7090B0")) {
                    showSettings = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(BrushedMetal(baseColor: Color(hex: "78C8F0"), intensity: 0.36))
            .overlay(
                VStack {
                    Rectangle().fill(Color.white.opacity(0.4)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Color(hex: "0080C0").opacity(0.22)).frame(height: 1)
                }
            )

            ChromeInset {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(folders.sorted(by: { $0.dateCreated < $1.dateCreated })) { folder in
                            FolderSection(
                                folder: folder,
                                memos: memosInFolder(folder),
                                selectedMemo: $selectedMemo,
                                allFolders: folders,
                                modelContext: modelContext,
                                onRenameFolder: { folderPendingRename = folder },
                                renameMemo: { memoPendingRename = $0 }
                            )
                        }

                        let unfiled = memos.filter { $0.folder == nil }
                        ForEach(unfiled) { memo in
                            MemoRow(
                                memo: memo,
                                isSelected: selectedMemo?.id == memo.id,
                                folders: folders,
                                modelContext: modelContext,
                                onRename: { memoPendingRename = memo }
                            ) { selectedMemo = memo }
                            .padding(.leading, 8)
                        }

                        if memos.isEmpty {
                            VStack(spacing: 8) {
                                Text("no memos yet")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Color(hex: "0870B0"))
                                Text("click + to import")
                                    .font(Theme.smallMetaFont)
                                    .foregroundStyle(Color(hex: "20A0D0"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(4)
                }
                .background(BrushedMetal(baseColor: Color(hex: "B0E0F8"), intensity: 0.28))
            }
            .padding(8)
        }
        .background(BrushedMetal(baseColor: Color(hex: "98D4F8"), intensity: 0.34))
    }

    private var detail: some View {
        ZStack {
            Theme.playerFaceGradient

            LinearGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear,
                    Color(hex: "00FFFF").opacity(0.08),
                    Color.clear,
                    Color.white.opacity(0.2),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            SubtleScanlines()

            if let memo = selectedMemo {
                TranscriptView(memo: memo)
            } else {
                EmptyStateView(importer: importer)
            }
        }
    }

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
            if let first = imported.first {
                selectedMemo = first
                importErrorMessage = nil
            } else if let err = importer.lastError {
                importErrorMessage = err
            }
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
                    if let first = imported.first {
                        selectedMemo = first
                        importErrorMessage = nil
                    } else if let err = importer.lastError {
                        importErrorMessage = err
                    }
                }
            }
        }
    }
}

struct FolderSection: View {
    let folder: Folder
    let memos: [Memo]
    @Binding var selectedMemo: Memo?
    let allFolders: [Folder]
    let modelContext: ModelContext
    let onRenameFolder: () -> Void
    let renameMemo: (Memo) -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button { isExpanded.toggle() } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "0080C0"))
                        .frame(width: 12)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "00B0FF"))

                    Text(folder.name.lowercased())
                        .font(Theme.captionFont)
                        .foregroundStyle(Color(hex: "0460A0"))

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Rename\u{2026}") { onRenameFolder() }
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
                        modelContext: modelContext,
                        onRename: { renameMemo(memo) }
                    ) { selectedMemo = memo }
                    .padding(.leading, 10)
                }
            }
        }
    }
}

struct MemoRow: View {
    let memo: Memo
    let isSelected: Bool
    let folders: [Folder]
    let modelContext: ModelContext
    let onRename: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button { onSelect() } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(Theme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : Color(hex: "044060"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(alignment: .center, spacing: 8) {
                    Text(memo.formattedDuration)
                        .font(Theme.smallMetaFont)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color(hex: "2090C8"))
                    Spacer(minLength: 4)
                    RetroStatusBadge(status: memo.status)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00A8FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                            .shadow(color: Color(hex: "00FFFF").opacity(0.4), radius: 6, y: 2)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename\u{2026}") { onRename() }
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
                TranscriptDiskExport.removeFile(for: memo.id)
                modelContext.delete(memo)
                try? modelContext.save()
            }
        }
    }
}
