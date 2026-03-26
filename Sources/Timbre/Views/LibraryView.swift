import SwiftUI
import SwiftData

struct LibraryView: View {
    let memos: [Memo]
    let folders: [Folder]
    @Binding var selectedMemo: Memo?
    let importer: AudioImporter
    let onCreateFolder: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var renamingMemo: Memo?
    @State private var renamingFolder: Folder?

    private var unfolderedMemos: [Memo] {
        let filtered = searchText.isEmpty
            ? memos
            : memos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return filtered.filter { $0.folder == nil }
    }

    private var sortedFolders: [Folder] {
        folders.sorted { $0.dateCreated < $1.dateCreated }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedMemo) {
                ForEach(sortedFolders) { folder in
                    Section {
                        ForEach(memosInFolder(folder)) { memo in
                            memoRow(memo).tag(memo)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.chromeMid)
                            Text(folder.name.lowercased())
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .contextMenu {
                            Button("Rename Folder\u{2026}") {
                                renamingFolder = folder
                            }
                            Divider()
                            Button("Delete Folder", role: .destructive) {
                                deleteFolder(folder)
                            }
                        }
                    }
                }

                if !unfolderedMemos.isEmpty {
                    Section(sortedFolders.isEmpty ? "" : "UNFILED") {
                        ForEach(unfolderedMemos) { memo in
                            memoRow(memo).tag(memo)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "search memos")
            .overlay {
                if memos.isEmpty && folders.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundStyle(Theme.chromeMid)
                        Text("no memos")
                            .font(Theme.titleFont)
                            .foregroundStyle(Theme.textSecondary)
                        Text("import a voice memo to get started")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textDim)
                    }
                }
            }

            // Bottom bar
            Rectangle()
                .fill(Theme.chromeDark.opacity(0.2))
                .frame(height: 1)

            HStack {
                Button {
                    onCreateFolder()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 11))
                        Text("new folder")
                            .font(Theme.captionFont)
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.sidebarBg.opacity(0.5))
        }
        .sheet(item: $renamingMemo) { memo in
            RetroRenameSheet(
                title: "rename memo",
                currentName: memo.title
            ) { newName in
                memo.title = newName
                try? modelContext.save()
            }
        }
        .sheet(item: $renamingFolder) { folder in
            RetroRenameSheet(
                title: "rename folder",
                currentName: folder.name
            ) { newName in
                folder.name = newName
                try? modelContext.save()
            }
        }
    }

    @ViewBuilder
    private func memoRow(_ memo: Memo) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(memo.title)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(memo.formattedDuration)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textDim)

                Text(memo.displayDate, style: .date)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textDim)

                Spacer()

                RetroStatusBadge(status: memo.status)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Rename\u{2026}") {
                renamingMemo = memo
            }

            if !folders.isEmpty {
                Menu("Move to Folder") {
                    ForEach(sortedFolders) { folder in
                        Button(folder.name) {
                            memo.folder = folder
                            try? modelContext.save()
                        }
                    }
                    if memo.folder != nil {
                        Divider()
                        Button("Remove from Folder") {
                            memo.folder = nil
                            try? modelContext.save()
                        }
                    }
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                if selectedMemo?.id == memo.id {
                    selectedMemo = nil
                }
                TranscriptDiskExport.removeFile(for: memo.id)
                modelContext.delete(memo)
                try? modelContext.save()
            }
        }
    }

    private func memosInFolder(_ folder: Folder) -> [Memo] {
        let memos = folder.memos.sorted { $0.dateImported > $1.dateImported }
        if searchText.isEmpty { return memos }
        return memos.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func deleteFolder(_ folder: Folder) {
        for memo in folder.memos {
            memo.folder = nil
        }
        modelContext.delete(folder)
        try? modelContext.save()
    }
}

// MARK: - Retro Status Badge

struct RetroStatusBadge: View {
    let status: MemoStatus

    var body: some View {
        Text(status.label)
            .font(Theme.badgeFont)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [badgeColor, badgeColor.opacity(0.75)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.75), badgeColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: badgeColor.opacity(0.35), radius: 3, y: 1)
    }

    private var badgeColor: Color {
        switch status {
        case .imported: Color(hex: "0088C8")
        case .transcribing: Color(hex: "00B0FF")
        case .completed: Color(hex: "00E070")
        case .failed: Color(hex: "FF4088")
        }
    }
}

// MARK: - Retro Rename Sheet

struct RetroRenameSheet: View {
    let title: String
    let currentName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)

            TextField("name", text: $text)
                .textFieldStyle(.squareBorder)
                .font(Theme.bodyFont)
                .focused($isFocused)
                .onSubmit { save() }

            HStack {
                Button("[ cancel ]") { dismiss() }
                    .font(Theme.captionFont)
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textDim)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("[ save ]") { save() }
                    .font(Theme.titleFont)
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5)
                    )
                    .shadow(color: Color(hex: "00C8FF").opacity(0.35), radius: 4, y: 2)
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    ).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
        .background(
            LinearGradient(
                colors: [Color(hex: "F0FCFF"), Color(hex: "D0E8FF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .textCase(.lowercase)
        .onAppear {
            text = currentName
            isFocused = true
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}
