import Foundation
import WhisperKit

@Observable
final class ModelManager {
    var availableModels: [WhisperModel] = WhisperModel.allCases
    var selectedModel: WhisperModel = .baseEn
    var downloadProgress: Double = 0
    var isDownloading = false
    var downloadedModels: Set<String> = []

    func refreshDownloadedModels() async {
        let supportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("Timbre/Models")

        guard let supportDir,
              let contents = try? FileManager.default
                  .contentsOfDirectory(atPath: supportDir.path)
        else { return }

        downloadedModels = Set(contents)
    }

    func isDownloaded(_ model: WhisperModel) -> Bool {
        downloadedModels.contains(model.name)
    }
}

enum WhisperModel: String, CaseIterable, Identifiable {
    case tinyEn = "tiny.en"
    case baseEn = "base.en"
    case smallEn = "small.en"
    case largeV3 = "large-v3"

    var id: String { rawValue }
    var name: String { rawValue }

    var displayName: String {
        switch self {
        case .tinyEn: "tiny (english)"
        case .baseEn: "base (english)"
        case .smallEn: "small (english)"
        case .largeV3: "large v3 (multilingual)"
        }
    }

    var description: String {
        switch self {
        case .tinyEn: "fastest, lowest accuracy. ~75 mb"
        case .baseEn: "fast, good for quick drafts. ~150 mb"
        case .smallEn: "balanced speed and accuracy. ~500 mb"
        case .largeV3: "best accuracy, multilingual. ~3 gb"
        }
    }

    var approximateSize: String {
        switch self {
        case .tinyEn: "75 MB"
        case .baseEn: "150 MB"
        case .smallEn: "500 MB"
        case .largeV3: "3 GB"
        }
    }
}
