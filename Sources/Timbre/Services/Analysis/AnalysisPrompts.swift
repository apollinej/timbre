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
}
