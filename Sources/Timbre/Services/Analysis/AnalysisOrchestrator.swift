import Foundation

actor AnalysisOrchestrator {
    private let provider: AnalysisProvider

    init(provider: AnalysisProvider = OpenAIProvider()) {
        self.provider = provider
    }

    func runFullAnalysis(
        transcript: String,
        title: String = "",
        duration: TimeInterval = 0,
        date: Date = .now
    ) async throws -> FullAnalysisResult {
        let userMessage = AnalysisPromptBuilder.userMessage(
            transcript: transcript,
            title: title,
            duration: duration,
            date: date
        )

        async let summaryResult = provider.analyze(
            transcript: userMessage, task: .summarize
        )
        async let actionsResult = provider.analyze(
            transcript: userMessage, task: .extractActionItems
        )
        async let threadsResult = provider.analyze(
            transcript: userMessage, task: .extractThreads
        )
        async let decisionsResult = provider.analyze(
            transcript: userMessage, task: .extractDecisions
        )

        let (s, a, t, d) = try await (
            summaryResult, actionsResult, threadsResult, decisionsResult
        )

        let (summary, notes) = parseSummary(s.text)
        return FullAnalysisResult(
            summary: summary,
            detailedNotes: notes,
            actionItems: parseList(a.text),
            decisions: parseList(d.text),
            threads: parseList(t.text)
        )
    }

    private func parseSummary(_ text: String) -> (String, String) {
        let parts = text.components(separatedBy: "---")
        if parts.count >= 2 {
            return (parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let paragraphs = text.components(separatedBy: "\n\n")
        if paragraphs.count >= 2 {
            let summary = paragraphs[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let notes = paragraphs.dropFirst().joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (summary, notes)
        }
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }

    private func parseList(_ text: String) -> [String] {
        text.components(separatedBy: "\n")
            .map { line in
                line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(
                        of: #"^[-*•]\s*|\d+[.)]\s*"#,
                        with: "",
                        options: .regularExpression
                    )
            }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }
}
