import Foundation

enum MemoStatus: Codable, Equatable {
    case imported
    case transcribing
    case completed
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
        case .imported: "Ready"
        case .transcribing: "Transcribing"
        case .completed: "Done"
        case .failed: "Failed"
        }
    }
}
