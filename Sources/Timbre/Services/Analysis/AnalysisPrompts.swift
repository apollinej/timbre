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

    /// Self-contained prompt the user pastes into any LLM. The output
    /// format below is strict on purpose — the parser splits the
    /// response by exact `## ` headers to populate MemoAnalysis fields.
    /// Keep these section names in sync with `parseManualResponse`.
    static func manualPrompt(for memo: Memo) -> String? {
        guard let transcript = memo.transcript else { return nil }
        let transcriptText = transcript.sortedSegments.map { seg in
            let name = seg.speaker?.effectiveName ?? "Speaker"
            return "[\(name)] (\(TimeFormatter.format(seg.startTime)))\n\(seg.text)"
        }.joined(separator: "\n\n")

        return """
        You are analyzing a meeting transcript. Output EXACTLY the sections below with the headers exactly as shown — no other sections, no preamble, no closing remarks. Use markdown.

        ## SUMMARY
        A 2-3 sentence executive summary. Lead with the most important outcome or decision.

        ## NOTES
        Detailed notes organized by topic (not chronologically). Use sub-headings (### Topic) and bullets. Attribute claims to speakers when possible. Include specifics, numbers, and implied context.

        ## DECISIONS
        One decision per bullet starting with "- ". Include who decided and why. If no decisions were made, write a single line: "- none".

        ## ACTIONS
        One action per bullet starting with "- ". Format each as "owner: what to do (by when if mentioned)". Example: "- apolline: draft the spec by friday". If no actions were committed, write: "- none".

        ## QUESTIONS
        One open question or unresolved thread per bullet starting with "- ". If none, write: "- none".

        ---

        **Meeting:** \(memo.title)
        **Duration:** \(memo.formattedDuration)
        **Date:** \(memo.displayDate.formatted(date: .long, time: .shortened))

        **Transcript:**

        \(transcriptText)
        """
    }

    /// Parse an LLM response (or hand-written markdown) into the same
    /// shape the API path produces. Forgiving: matches headers
    /// case-insensitively and accepts common synonyms.
    static func parseManualResponse(_ text: String) -> FullAnalysisResult {
        var sections: [String: String] = [:]
        var currentKey: String?
        var buffer: [String] = []

        func flush() {
            if let key = currentKey {
                sections[key] = buffer.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            buffer.removeAll(keepingCapacity: true)
        }

        // Only EXACTLY "## " (two hashes followed by space) starts a new
        // section. `### Subheading` is treated as content within the current
        // section so the LLM can structure its NOTES however it likes.
        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("## ") && !line.hasPrefix("### ") {
                flush()
                currentKey = String(line.dropFirst(3))
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
            } else {
                buffer.append(line)
            }
        }
        flush()

        func section(_ candidates: [String]) -> String {
            for c in candidates {
                if let value = sections[c], !value.isEmpty { return value }
            }
            return ""
        }

        let summary = section(["summary", "executive summary", "tl;dr"])
        let notes = section(["notes", "detailed notes"])
        let decisionsText = section(["decisions", "key decisions"])
        let actionsText = section(["actions", "action items", "actions & owners"])
        let questionsText = section(["questions", "open questions", "open threads", "questions & follow-ups"])

        // If the user pasted raw markdown without any recognizable
        // section headers, fall back to the whole blob as notes so
        // nothing is lost.
        let anyParsed = !summary.isEmpty || !notes.isEmpty
            || !decisionsText.isEmpty || !actionsText.isEmpty || !questionsText.isEmpty
        let finalNotes = anyParsed
            ? notes
            : text.trimmingCharacters(in: .whitespacesAndNewlines)

        return FullAnalysisResult(
            summary: summary,
            detailedNotes: finalNotes,
            actionItems: parseBullets(actionsText),
            decisions: parseBullets(decisionsText),
            threads: parseBullets(questionsText)
        )
    }

    /// Reverse of parseManualResponse — render a MemoAnalysis as
    /// markdown the user can edit, using the exact same section headers.
    /// Round-trippable: parse(render(analysis)) reproduces analysis.
    static func renderAnalysisMarkdown(_ analysis: MemoAnalysis?) -> String {
        guard let a = analysis else { return "" }
        var parts: [String] = []

        if let s = a.summary, !s.isEmpty {
            parts.append("## SUMMARY\n\(s)")
        }
        if !a.keyDecisions.isEmpty {
            let body = a.keyDecisions.map { "- \($0.text)" }.joined(separator: "\n")
            parts.append("## DECISIONS\n\(body)")
        }
        if !a.actionItems.isEmpty {
            let body = a.actionItems.map { "- \($0.text)" }.joined(separator: "\n")
            parts.append("## ACTIONS\n\(body)")
        }
        if !a.openThreads.isEmpty {
            let body = a.openThreads.map { "- \($0.text)" }.joined(separator: "\n")
            parts.append("## QUESTIONS\n\(body)")
        }
        if let n = a.detailedNotes, !n.isEmpty {
            parts.append("## NOTES\n\(n)")
        }
        return parts.joined(separator: "\n\n")
    }

    private static func parseBullets(_ text: String) -> [String] {
        text.components(separatedBy: .newlines).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { return nil }
            for prefix in ["- ", "* ", "• ", "– ", "— "] {
                if line.hasPrefix(prefix) {
                    let body = String(line.dropFirst(prefix.count))
                        .trimmingCharacters(in: .whitespaces)
                    if body.lowercased() == "none" { return nil }
                    return body.isEmpty ? nil : body
                }
            }
            // Numbered list: "1. " / "12) "
            if let firstNonDigit = line.firstIndex(where: { !$0.isNumber }) {
                let head = line[line.startIndex..<firstNonDigit]
                if !head.isEmpty {
                    let rest = line[firstNonDigit...]
                    if rest.hasPrefix(". ") || rest.hasPrefix(") ") {
                        let body = String(rest.dropFirst(2))
                            .trimmingCharacters(in: .whitespaces)
                        if body.lowercased() == "none" { return nil }
                        return body.isEmpty ? nil : body
                    }
                }
            }
            return nil
        }
    }
}
