import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID
    var title: String
    var sourceURL: URL
    var audioBookmark: Data?
    var dateImported: Date
    var dateRecorded: Date?
    var duration: TimeInterval
    var fileSize: Int64
    @Relationship(deleteRule: .cascade) var transcript: Transcript?
    @Relationship(deleteRule: .cascade) var analysis: MemoAnalysis?
    var folder: Folder?
    var status: MemoStatus
    var transcriptionProgress: Double
    var workspaceID: UUID?
    var timezoneID: String?
    var location: String?
    var context: String?

    init(
        title: String,
        sourceURL: URL,
        audioBookmark: Data? = nil,
        dateRecorded: Date? = nil,
        duration: TimeInterval = 0,
        fileSize: Int64 = 0
    ) {
        self.id = UUID()
        self.title = title
        self.sourceURL = sourceURL
        self.audioBookmark = audioBookmark
        self.dateImported = .now
        self.dateRecorded = dateRecorded
        self.duration = duration
        self.fileSize = fileSize
        self.status = .imported
        self.transcriptionProgress = 0
    }

    var displayDate: Date {
        dateRecorded ?? dateImported
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var timezone: TimeZone? {
        get { timezoneID.flatMap { TimeZone(identifier: $0) } }
        set { timezoneID = newValue?.identifier }
    }
}
