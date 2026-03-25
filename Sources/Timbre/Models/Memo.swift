import Foundation
import SwiftData

enum MemoStatus: Codable, Equatable {
    case imported
    case transcribing(progress: Double)
    case completed
    case failed(error: String)

    var isTranscribing: Bool {
        if case .transcribing = self { return true }
        return false
    }

    var progress: Double {
        if case .transcribing(let p) = self { return p }
        return 0
    }
}

@Model
final class Memo {
    var id: UUID
    var title: String
    var sourceURL: URL
    var audioBookmark: Data
    var dateImported: Date
    var dateRecorded: Date?
    var duration: TimeInterval
    var fileSize: Int64
    @Relationship(deleteRule: .cascade) var transcript: Transcript?
    var status: MemoStatus

    init(
        title: String,
        sourceURL: URL,
        audioBookmark: Data,
        dateRecorded: Date? = nil,
        duration: TimeInterval,
        fileSize: Int64
    ) {
        self.id = UUID()
        self.title = title
        self.sourceURL = sourceURL
        self.audioBookmark = audioBookmark
        self.dateImported = Date()
        self.dateRecorded = dateRecorded
        self.duration = duration
        self.fileSize = fileSize
        self.transcript = nil
        self.status = .imported
    }

    /// Resolve the security-scoped bookmark back to a URL
    func resolveBookmark() -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: audioBookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        return url
    }
}
