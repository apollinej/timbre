import Foundation

protocol AnalysisProvider: Sendable {
    var name: String { get }
    func analyze(transcript: String, task: AnalysisTask) async throws -> AnalysisResult
}

enum AnalysisTask: Sendable {
    case summarize
    case extractActionItems
    case extractThreads
    case extractDecisions
    case freeform(String)
}

struct AnalysisResult: Sendable {
    let text: String
    let task: AnalysisTask
}

struct FullAnalysisResult: Sendable {
    let summary: String
    let detailedNotes: String
    let actionItems: [String]
    let decisions: [String]
    let threads: [String]
}

enum AnalysisError: LocalizedError {
    case noAPIKey
    case invalidResponse(Int)
    case decodingFailed(String)
    case networkError(Error)
    case noTranscript

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "set your openai key in settings first"
        case .invalidResponse(401):
            return "invalid api key — check settings"
        case .invalidResponse(429):
            return "rate limited — try again in a moment"
        case .invalidResponse(let code):
            return "api error (status \(code))"
        case .decodingFailed(let detail):
            return "failed to parse response: \(detail)"
        case .networkError:
            return "network error — check your connection"
        case .noTranscript:
            return "no transcript to analyze"
        }
    }
}
