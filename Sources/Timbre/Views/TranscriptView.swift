import SwiftUI
import SwiftData

struct TranscriptView: View {
    let memo: Memo
    @State private var viewModel = TranscriptViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var transcriptionEngine = TranscriptionEngine()

    var body: some View {
        VStack(spacing: 0) {
            // Waveform
            WaveformView(
                samples: viewModel.waveformSamples,
                currentTime: viewModel.currentTime,
                duration: memo.duration
            )
            .frame(height: 80)
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Transcript content
            if let transcript = memo.transcript {
                transcriptContent(transcript)
            } else {
                transcriptionPlaceholder
            }

            Divider()

            // Playback bar
            PlaybackBar(viewModel: viewModel, duration: memo.duration)
        }
        .navigationTitle(memo.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ExportButton(memo: memo)
            }
        }
        .onAppear { viewModel.load(memo: memo) }
        .onChange(of: memo) { _, newMemo in
            viewModel.load(memo: newMemo)
        }
    }

    private func transcriptContent(_ transcript: Transcript) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(transcript.sortedSegments) { segment in
                        SegmentRow(
                            segment: segment,
                            isActive: viewModel.currentSegmentID == segment.id,
                            onTap: { viewModel.seekToSegment(segment) }
                        )
                        .id(segment.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.currentSegmentID) { _, newID in
                if let id = newID {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var transcriptionPlaceholder: some View {
        switch memo.status {
        case .transcribing(let progress):
            TranscriptionProgressView(
                progress: progress,
                onCancel: { /* TODO: cancel transcription */ }
            )
        case .failed(let error):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text(error)
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    startTranscription()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            VStack(spacing: 16) {
                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Ready to transcribe")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Button("Start Transcription") {
                    startTranscription()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func startTranscription() {
        let model = ModelManager.shared.selectedModel
        memo.status = .transcribing(progress: 0)

        Task {
            guard let url = memo.resolveBookmark() else {
                memo.status = .failed(error: "Could not access audio file.")
                return
            }

            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let segments = try await transcriptionEngine.transcribe(
                    audioURL: url,
                    modelName: model.rawValue
                ) { progress in
                    Task { @MainActor in
                        memo.status = .transcribing(progress: progress.fractionCompleted)
                    }
                }

                await MainActor.run {
                    let transcript = Transcript(modelUsed: model.rawValue)
                    var speakerCache: [String: Speaker] = [:]
                    var speakerIndex = 0

                    for seg in segments {
                        let speaker: Speaker
                        if let existing = speakerCache[seg.speakerLabel] {
                            speaker = existing
                        } else {
                            speaker = Speaker(
                                label: seg.speakerLabel,
                                colorHex: SpeakerColors.color(for: speakerIndex)
                            )
                            modelContext.insert(speaker)
                            speakerCache[seg.speakerLabel] = speaker
                            speakerIndex += 1
                        }

                        let segment = Segment(
                            text: seg.text,
                            startTime: seg.startTime,
                            endTime: seg.endTime,
                            speaker: speaker,
                            confidence: seg.confidence
                        )
                        segment.transcript = transcript
                        modelContext.insert(segment)
                        transcript.segments.append(segment)
                    }

                    modelContext.insert(transcript)
                    memo.transcript = transcript
                    memo.status = .completed
                    try? modelContext.save()
                }
            } catch {
                await MainActor.run {
                    memo.status = .failed(error: error.localizedDescription)
                }
            }
        }
    }
}
