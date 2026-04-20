import Foundation

enum MemoStatus: Codable, Equatable {
    case imported
    case transcribing
    case completed
    case analyzed
    case failed(error: String)

    var isTranscribing: Bool {
        if case .transcribing = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var label: String {
        switch self {
        case .imported: "ready"
        case .transcribing: "transcribing"
        case .completed: "done"
        case .analyzed: "analyzed"
        case .failed: "failed"
        }
    }
}
