import Foundation

extension AnalysisTask {
    var systemPrompt: String {
        switch self {
        case .summarize:
            return """
            You are a senior executive assistant analyzing a meeting transcript.

            Produce TWO sections separated by "---":

            SECTION 1 — EXECUTIVE SUMMARY
            Write 2-3 sentences capturing the core purpose, key outcomes, and \
            most important takeaway from this meeting.

            SECTION 2 — DETAILED NOTES
            Organize the meeting content by topic (not chronologically). Use \
            clear headers for each topic. Under each header, write concise \
            bullet points capturing what was discussed, any context shared, \
            and conclusions reached. Be thorough but not verbose.

            Write in lowercase. No preamble. Start directly with the summary.
            """

        case .extractActionItems:
            return """
            You are analyzing a meeting transcript for action items.

            Extract every commitment, task, or follow-up mentioned. For each:
            - Start with the owner's name if mentioned (e.g. "sarah: ")
            - Describe the specific action clearly and concisely
            - Include any deadline if mentioned

            One item per line, starting with "- ". \
            Only include concrete actions, not vague intentions. \
            Write in lowercase. No preamble.
            """

        case .extractThreads:
            return """
            You are analyzing a meeting transcript for open questions \
            and unresolved threads.

            Extract every question that was raised but not definitively \
            answered, every topic that needs further discussion, and every \
            decision that was deferred.

            One item per line, starting with "- ". \
            Be specific about what remains unresolved. \
            Write in lowercase. No preamble.
            """

        case .extractDecisions:
            return """
            You are analyzing a meeting transcript for key decisions.

            Extract every decision that was made or confirmed during the \
            meeting. Include the reasoning or context behind each decision \
            when available.

            One item per line, starting with "- ". \
            Only include definitive decisions, not proposals or suggestions. \
            Write in lowercase. No preamble.
            """

        case .freeform(let prompt):
            return prompt
        }
    }
}

enum AnalysisPromptBuilder {
    static func userMessage(
        transcript: String,
        title: String,
        duration: TimeInterval,
        date: Date
    ) -> String {
        let mins = Int(duration / 60)
        let dateStr = date.formatted(date: .abbreviated, time: .shortened)
        return """
        meeting: \(title)
        date: \(dateStr)
        duration: \(mins) minutes

        transcript:
        \(transcript)
        """
    }

    /// Self-contained prompt the user can paste into any LLM
    /// (ChatGPT, Claude, etc.) without an API key. Output is structured
    /// markdown the user can paste back via "paste your own".
    static func manualPrompt(for memo: Memo) -> String? {
        guard let transcript = memo.transcript else { return nil }
        let transcriptText = transcript.sortedSegments.map { seg in
            let name = seg.speaker?.effectiveName ?? "Speaker"
            return "[\(name)] (\(TimeFormatter.format(seg.startTime)))\n\(seg.text)"
        }.joined(separator: "\n\n")

        return """
        You are a senior consultant producing structured meeting documentation. Analyze this transcript and produce executive-quality notes.

        ## Output Format (paste this back into timbre exactly as-is)

        ### Executive Summary
        2-3 sentences. Lead with the most important outcome.

        ### Detailed Notes
        Organized by topic, not chronologically. For each topic:
        - **Topic heading** in bold
        - What was discussed, with attribution to speakers
        - Any specifics, numbers, data points
        - Implied context

        ### Key Decisions
        - One decision per bullet
        - Include who decided and why

        ### Action Items
        - Owner: action — deadline (if mentioned)

        ### Open Questions
        - Items raised but not resolved

        ---

        **Meeting:** \(memo.title)
        **Duration:** \(memo.formattedDuration)
        **Date:** \(memo.displayDate.formatted(date: .long, time: .shortened))

        **Transcript:**

        \(transcriptText)
        """
    }
}
