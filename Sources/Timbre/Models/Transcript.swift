import Foundation
import SwiftData

@Model
final class Transcript {
    var id: UUID
    @Relationship(deleteRule: .cascade) var segments: [Segment]
    var modelUsed: String
    var dateTranscribed: Date
    var language: String?

    init(
        segments: [Segment] = [],
        modelUsed: String,
        dateTranscribed: Date = .now,
        language: String? = nil
    ) {
        self.id = UUID()
        self.segments = segments
        self.modelUsed = modelUsed
        self.dateTranscribed = dateTranscribed
        self.language = language
    }

    var sortedSegments: [Segment] {
        segments.sorted { $0.startTime < $1.startTime }
    }

    var speakerCount: Int {
        Set(segments.compactMap { $0.speaker?.id }).count
    }
}
