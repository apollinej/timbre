import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "md"
    case plainText = "txt"
    case srt = "srt"
    case json = "json"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdown: "Markdown"
        case .plainText: "Plain Text"
        case .srt: "SRT Subtitles"
        case .json: "JSON"
        }
    }

    var fileExtension: String { rawValue }
}

enum ExportService {
    static func export(
        transcript: Transcript,
        memoTitle: String,
        duration: TimeInterval,
        format: ExportFormat
    ) -> String {
        switch format {
        case .markdown: markdownExport(transcript, title: memoTitle, duration: duration)
        case .plainText: plainTextExport(transcript)
        case .srt: srtExport(transcript)
        case .json: jsonExport(transcript, title: memoTitle)
        }
    }

    private static func markdownExport(
        _ transcript: Transcript,
        title: String,
        duration: TimeInterval
    ) -> String {
        let segments = transcript.sortedSegments
        let speakers = uniqueSpeakers(from: segments)

        var output = "# \(title)\n\n"
        output += "**Duration:** \(TimeFormatter.format(duration))\n"
        output += "**Speakers:** \(speakers.joined(separator: ", "))\n"
        output += "**Model:** \(transcript.modelUsed)\n\n---\n\n"

        for segment in segments {
            let name = segment.speaker?.name ?? "Unknown"
            let time = TimeFormatter.format(segment.startTime)
            output += "**\(name)** (\(time))\n\(segment.text)\n\n"
        }

        return output
    }

    private static func plainTextExport(_ transcript: Transcript) -> String {
        transcript.sortedSegments.map { segment in
            let name = segment.speaker?.name ?? "Unknown"
            let time = TimeFormatter.format(segment.startTime)
            return "[\(name)] (\(time)) \(segment.text)"
        }.joined(separator: "\n\n")
    }

    private static func srtExport(_ transcript: Transcript) -> String {
        transcript.sortedSegments.enumerated().map { index, segment in
            let name = segment.speaker?.name ?? "Unknown"
            let start = TimeFormatter.formatSRT(segment.startTime)
            let end = TimeFormatter.formatSRT(segment.endTime)
            return "\(index + 1)\n\(start) --> \(end)\n[\(name)] \(segment.text)"
        }.joined(separator: "\n\n")
    }

    private static func jsonExport(_ transcript: Transcript, title: String) -> String {
        let segments = transcript.sortedSegments.map { segment -> [String: Any] in
            var dict: [String: Any] = [
                "text": segment.text,
                "startTime": segment.startTime,
                "endTime": segment.endTime,
                "speaker": segment.speaker?.name ?? "Unknown"
            ]
            if let confidence = segment.confidence {
                dict["confidence"] = confidence
            }
            return dict
        }

        let root: [String: Any] = [
            "title": title,
            "model": transcript.modelUsed,
            "language": transcript.language ?? "en",
            "dateTranscribed": ISO8601DateFormatter().string(from: transcript.dateTranscribed),
            "segments": segments
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        ),
              let json = String(data: data, encoding: .utf8)
        else { return "{}" }

        return json
    }

    private static func uniqueSpeakers(from segments: [Segment]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for segment in segments {
            let name = segment.speaker?.name ?? "Unknown"
            if seen.insert(name).inserted {
                result.append(name)
            }
        }
        return result
    }
}
