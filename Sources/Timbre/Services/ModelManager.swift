import Foundation
import WhisperKit

enum WhisperModel: String, CaseIterable, Identifiable {
    case tinyEn = "tiny.en"
    case baseEn = "base.en"
    case smallEn = "small.en"
    case largeV3 = "large-v3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tinyEn: "Tiny (English)"
        case .baseEn: "Base (English)"
        case .smallEn: "Small (English)"
        case .largeV3: "Large v3 (Multilingual)"
        }
    }

    var sizeDescription: String {
        switch self {
        case .tinyEn: "~75 MB"
        case .baseEn: "~150 MB"
        case .smallEn: "~500 MB"
        case .largeV3: "~3 GB"
        }
    }

    var requiresHighRAM: Bool {
        self == .largeV3
    }
}

@Observable
final class ModelManager {
    var selectedModel: WhisperModel = .baseEn
    var isDownloading = false
    var downloadProgress: Double = 0

    static let shared = ModelManager()

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedModel"),
           let model = WhisperModel(rawValue: saved) {
            selectedModel = model
        }
    }

    func selectModel(_ model: WhisperModel) {
        selectedModel = model
        UserDefaults.standard.set(model.rawValue, forKey: "selectedModel")
    }

    var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        let dir = appSupport.appendingPathComponent("Timbre/Models")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
