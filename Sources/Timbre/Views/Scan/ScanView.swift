import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.dateImported, order: .reverse) private var allMemos: [Memo]
    @State private var vm = ScanViewModel()
    @State private var importer = AudioImporter()
    @State private var importErrorMessage: String?
    let onGoHome: () -> Void
    let onOpenMemo: (Memo) -> Void
    /// Optional memo to surface in the side panel when Scan first appears,
    /// used by Debrief's meeting chip to open Browse with the relevant
    /// memo already selected.
    var initialSelection: Memo? = nil

    private var filteredMemos: [Memo] { vm.filtered(allMemos) }

    /// Speaker chips derived from the actual segments in current memos.
    /// One chip per unique effective name (case-insensitive). Falls through
    /// the Person table entirely — Person records may be stale or absent.
    private var displayedSpeakers: [SpeakerChipModel] {
        var byName: [String: SpeakerChipModel] = [:]
        for memo in allMemos {
            for seg in memo.transcript?.segments ?? [] {
                guard let s = seg.speaker else { continue }
                let key = s.effectiveName.lowercased()
                if byName[key] == nil {
                    byName[key] = SpeakerChipModel(
                        name: s.effectiveName,
                        colorHex: s.colorHex
                    )
                }
            }
        }
        return byName.values.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    struct SpeakerChipModel: Identifiable {
        let name: String
        let colorHex: String
        var id: String { name.lowercased() }
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                headerBanner
                filterBar
                viewModeAndSortBar
                mainContent
            }
        }
        .alert("import failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("ok", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .onAppear {
            if let target = initialSelection, vm.selectedMemo?.id != target.id {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.selectedMemo = target
                }
            }
        }
        .onChange(of: initialSelection?.id) { _, _ in
            if let target = initialSelection {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.selectedMemo = target
                }
            }
        }
    }

    private var background: some View {
        ZStack { Theme.playerFaceGradient; SubtleScanlines() }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "B0E0F8"), intensity: 0.32)
            VStack {
                Rectangle().fill(Color.white.opacity(0.55)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color(hex: "0080C0").opacity(0.18)).frame(height: 1)
            }
            Text("browse")
                .font(TimbreFont.fontBold(size: 22))
                .foregroundStyle(Color(hex: "004878"))
            HStack {
                BubbleButton(icon: "plus", size: 32, color: Color(hex: "0088FF")) {
                    importFiles()
                }
                .padding(.leading, 12)
                Spacer()
                HomeButton(action: onGoHome).padding(.trailing, 12)
            }
        }
        .frame(height: 48)
    }

    private func importFiles() {
        let urls = AudioImporter.presentImportPanel()
        guard !urls.isEmpty else { return }
        Task {
            let imported = await importer.importFiles(urls, into: modelContext)
            if imported.isEmpty, let err = importer.lastError {
                importErrorMessage = err
            } else {
                importErrorMessage = nil
            }
        }
    }

    // MARK: - Filters

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Speaker chips — derived from segments in current memos
            if !displayedSpeakers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(displayedSpeakers) { speaker in
                            TimbreColoredChip(
                                label: speaker.name.lowercased(),
                                colorHex: speaker.colorHex,
                                isSelected: vm.selectedSpeakerNames.contains(speaker.id)
                            ) {
                                if vm.selectedSpeakerNames.contains(speaker.id) {
                                    vm.selectedSpeakerNames.remove(speaker.id)
                                } else {
                                    vm.selectedSpeakerNames.insert(speaker.id)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                // Time pills
                ForEach(ScanViewModel.TimeFilter.allCases, id: \.self) { tf in
                    TimbreTogglePill(
                        label: tf.rawValue,
                        isSelected: vm.timeFilter == tf
                    ) { vm.timeFilter = tf }
                }

                Spacer()

                // Keyword search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "0088C8"))
                    TextField("search\u{2026}", text: $vm.keyword)
                        .textFieldStyle(.plain)
                        .font(TimbreFont.font(size: 13))
                        .frame(width: 120)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.white.opacity(0.5))
                        .overlay(Capsule().strokeBorder(Color(hex: "0080C0").opacity(0.2)))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(hex: "D8F4FF"), Color(hex: "C8ECFF")],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - View mode + sort

    private var viewModeAndSortBar: some View {
        HStack(spacing: 0) {
            // View mode icons
            ForEach(ScanViewModel.ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { vm.viewMode = mode }
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            vm.viewMode == mode ? Color(hex: "0088FF") : Color(hex: "2090C8")
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            vm.viewMode == mode ? Color(hex: "00D8FF").opacity(0.12) : Color.clear
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Sort toggle
            ForEach(ScanViewModel.SortOrder.allCases, id: \.self) { order in
                TimbreTogglePill(
                    label: order.rawValue,
                    isSelected: vm.sortOrder == order
                ) { vm.sortOrder = order }
            }
            .padding(.trailing, 14)
        }
        .background(BrushedMetal(baseColor: Color(hex: "C0E8F8"), intensity: 0.22))
        .overlay(
            VStack {
                Spacer()
                Rectangle().fill(Color(hex: "0080C0").opacity(0.12)).frame(height: 1)
            }
        )
    }

    // MARK: - Main content with optional side panel

    private var mainContent: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left: cards/list/calendar
                Group {
                    if filteredMemos.isEmpty {
                        emptyState
                    } else {
                        contentView
                    }
                }
                .frame(width: vm.selectedMemo != nil ? geo.size.width * 0.5 : geo.size.width)

                // Right: side panel — half the page
                if let memo = vm.selectedMemo {
                    MemoSidePanel(
                        memo: memo,
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) { vm.selectedMemo = nil }
                        },
                        onPrevious: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.selectPrevious(in: filteredMemos)
                            }
                        },
                        onNext: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.selectNext(in: filteredMemos)
                            }
                        },
                        onOpenAnalyze: { onOpenMemo(memo) }
                    )
                    .frame(width: geo.size.width * 0.5)
                    .transition(.move(edge: .trailing))
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch vm.viewMode {
        case .card:
            ScanCardGrid(memos: filteredMemos) { memo in
                withAnimation(.easeInOut(duration: 0.2)) { vm.selectedMemo = memo }
            }
        case .list:
            ScanListView(memos: filteredMemos) { memo in
                withAnimation(.easeInOut(duration: 0.2)) { vm.selectedMemo = memo }
            }
        case .calendar:
            ScanCalendarView(memos: filteredMemos) { memo in
                withAnimation(.easeInOut(duration: 0.2)) { vm.selectedMemo = memo }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Text(allMemos.isEmpty ? "no memos yet" : "no matches")
                .font(TimbreFont.fontBold(size: 16))
                .foregroundStyle(Color(hex: "044060"))
            Text(allMemos.isEmpty ? "record or import a voice memo to get started" : "try clearing filters or widening the time range")
                .font(Theme.captionFont)
                .foregroundStyle(Color(hex: "2090C8"))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
