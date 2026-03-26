import Foundation

@Observable
final class SettingsViewModel {
    var selectedModel: WhisperModel = .baseEn
    var autoTranscribe = false
}
