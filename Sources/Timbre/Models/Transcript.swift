import Foundation
import SwiftData

@Model
final class Transcript {
    var id: UUID
    @Relationship(deleteRule: .cascade, inverse: \Segment.transcript) var segments: [Segment]
    var modelUsed: String
    var dateTranscribed: Date
    var language: String?

    init(modelUsed: String, language: String? = nil) {
        self.id = UUID()
        self.segments = []
        self.modelUsed = modelUsed
        self.dateTranscribed = Date()
        self.language = language
    }

    var sortedSegments: [Segment] {
        segments.sorted { $0.startTime < $1.startTime }
    }

    var fullText: String {
        sortedSegments.map { $0.text }.joined(separator: " ")
    }
}
