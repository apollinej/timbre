import Foundation

struct LocalAnalysisProvider: AnalysisProvider {
    let name = "local"

    func analyze(
        transcript: String,
        task: AnalysisTask
    ) async throws -> AnalysisResult {
        throw LocalAnalysisError.notYetImplemented
    }
}

private enum LocalAnalysisError: LocalizedError {
    case notYetImplemented

    var errorDescription: String? {
        "local analysis coming in a future update"
    }
}
