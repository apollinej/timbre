import Foundation
import SwiftData

@Model
final class Segment {
    var id: UUID
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    @Relationship var speaker: Speaker?
    @Relationship var transcript: Transcript?
    var confidence: Float?

    init(
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        speaker: Speaker? = nil,
        confidence: Float? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.speaker = speaker
        self.confidence = confidence
    }

    var durationText: String {
        TimeFormatter.format(startTime)
    }

    var rangeText: String {
        "\(TimeFormatter.format(startTime)) – \(TimeFormatter.format(endTime))"
    }
}
