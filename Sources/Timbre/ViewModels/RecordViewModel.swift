import Foundation
import SwiftData

@MainActor @Observable
final class RecordViewModel {
    let recorder = AudioRecorder()
    var showSavePopup = false
    var showPostSavePrompt = false
    var pendingPostSave = false
    var savedMemo: Memo?
    private var lastRecordedURL: URL?

    // Save popup fields
    var memoTitle = ""
    var memoContext = ""
    var memoLocation = ""
    var memoDate = Date()
    var selectedPersons: [Person] = []

    var isRecording: Bool { recorder.state == .recording }
    var isPaused: Bool { recorder.state == .paused }
    var isIdle: Bool { recorder.state == .idle }

    func startRecording() {
        do {
            try recorder.startRecording()
        } catch {
            print("[Timbre] Recording failed to start: \(error)")
        }
    }

    func togglePause() {
        if recorder.state == .recording {
            recorder.pauseRecording()
        } else if recorder.state == .paused {
            try? recorder.resumeRecording()
        }
    }

    func stopRecording() {
        // Capture the URL BEFORE stopRecording clears it
        lastRecordedURL = recorder.tempURL
        _ = recorder.stopRecording()
        guard lastRecordedURL != nil else { return }
        prefillSaveFields()
        showSavePopup = true
    }

    func saveMemo(context: ModelContext) -> Memo? {
        guard let url = lastRecordedURL else {
            print("[Timbre] saveMemo: no recorded URL available")
            return nil
        }

        // Move to library
        let ext = url.pathExtension
        let destName = "\(UUID().uuidString).\(ext)"
        let destURL = TimbrePaths.library.appendingPathComponent(destName)
        try? FileManager.default.moveItem(at: url, to: destURL)

        let fileSize = (try? FileManager.default.attributesOfItem(
            atPath: destURL.path
        )[.size] as? Int64) ?? 0

        let memo = Memo(
            title: memoTitle.isEmpty ? defaultTitle() : memoTitle,
            sourceURL: destURL,
            dateRecorded: memoDate,
            duration: recorder.elapsedTime,
            fileSize: fileSize
        )
        memo.context = memoContext.isEmpty ? nil : memoContext
        memo.location = memoLocation.isEmpty ? nil : memoLocation
        memo.timezone = TimeZone.current

        context.insert(memo)
        try? context.save()

        savedMemo = memo
        lastRecordedURL = nil
        showSavePopup = false
        pendingPostSave = true
        resetFields()
        return memo
    }

    func discard() {
        if let url = lastRecordedURL {
            try? FileManager.default.removeItem(at: url)
        }
        lastRecordedURL = nil
        recorder.discardRecording()
        showSavePopup = false
        resetFields()
    }

    func dismissPostSave() {
        showPostSavePrompt = false
        savedMemo = nil
    }

    private func prefillSaveFields() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        memoTitle = "Recording — \(formatter.string(from: Date()))"
        memoDate = Date()
        memoContext = ""
        memoLocation = ""
        selectedPersons = []
    }

    private func resetFields() {
        memoTitle = ""
        memoContext = ""
        memoLocation = ""
        selectedPersons = []
    }

    private func defaultTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return "Recording — \(formatter.string(from: Date()))"
    }

}
