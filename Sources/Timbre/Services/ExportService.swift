import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "md"
    case plainText = "txt"
    case srt = "srt"
    case json = "json"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .markdown: "Markdown"
        case .plainText: "Plain Text"
        case .srt: "SRT"
        case .json: "JSON"
        }
    }

    var fileExtension: String { rawValue }
}

enum ExportService {
    static func export(
        memo: Memo,
        format: ExportFormat
    ) -> String? {
        guard let transcript = memo.transcript else { return nil }

        switch format {
        case .markdown: return exportMarkdown(memo: memo, transcript: transcript)
        case .plainText: return exportPlainText(memo: memo, transcript: transcript)
        case .srt: return exportSRT(transcript: transcript)
        case .json: return exportJSON(memo: memo, transcript: transcript)
        }
    }

    private static func exportMarkdown(
        memo: Memo,
        transcript: Transcript
    ) -> String {
        var lines: [String] = []
        lines.append("# \(memo.title)")
        lines.append("")
        lines.append("**Duration:** \(memo.formattedDuration)")

        let speakers = uniqueSpeakers(transcript)
        if !speakers.isEmpty {
            lines.append("**Speakers:** \(speakers.joined(separator: ", "))")
        }

        lines.append("")
        lines.append("---")
        lines.append("")

        for segment in transcript.sortedSegments {
            let name = segment.speaker?.effectiveName ?? "Unknown"
            let time = TimeFormatter.format(segment.startTime)
            lines.append("**\(name)** (\(time))")
            lines.append(segment.text)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func exportPlainText(
        memo: Memo,
        transcript: Transcript
    ) -> String {
        var lines: [String] = []
        lines.append(memo.title)
        lines.append("Duration: \(memo.formattedDuration)")
        lines.append("")

        for segment in transcript.sortedSegments {
            let name = segment.speaker?.effectiveName ?? "Unknown"
            let time = TimeFormatter.format(segment.startTime)
            lines.append("\(name) (\(time))")
            lines.append(segment.text)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func exportSRT(transcript: Transcript) -> String {
        var lines: [String] = []

        for (index, segment) in transcript.sortedSegments.enumerated() {
            let name = segment.speaker?.effectiveName ?? "Unknown"
            lines.append("\(index + 1)")
            lines.append(
                "\(TimeFormatter.formatSRT(segment.startTime)) --> \(TimeFormatter.formatSRT(segment.endTime))"
            )
            lines.append("[\(name)] \(segment.text)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func exportJSON(
        memo: Memo,
        transcript: Transcript
    ) -> String {
        let data: [String: Any] = [
            "title": memo.title,
            "duration": memo.duration,
            "dateRecorded": memo.dateRecorded?.ISO8601Format() ?? "",
            "dateTranscribed": transcript.dateTranscribed.ISO8601Format(),
            "model": transcript.modelUsed,
            "language": transcript.language ?? "",
            "segments": transcript.sortedSegments.map { segment in
                [
                    "text": segment.text,
                    "startTime": segment.startTime,
                    "endTime": segment.endTime,
                    "speaker": segment.speaker?.effectiveName ?? "Unknown",
                    "confidence": segment.confidence ?? 0,
                ] as [String: Any]
            },
        ]

        guard let json = try? JSONSerialization.data(
            withJSONObject: data,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }

        return String(data: json, encoding: .utf8) ?? "{}"
    }

    private static func uniqueSpeakers(_ transcript: Transcript) -> [String] {
        var seen: Set<UUID> = []
        var names: [String] = []
        for segment in transcript.sortedSegments {
            guard let speaker = segment.speaker, !seen.contains(speaker.id) else {
                continue
            }
            seen.insert(speaker.id)
            names.append(speaker.effectiveName)
        }
        return names
    }
}
