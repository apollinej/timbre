import Foundation

@Observable
final class SettingsViewModel {
    var modelManager = ModelManager.shared
    var autoTranscribe: Bool {
        didSet { UserDefaults.standard.set(autoTranscribe, forKey: "autoTranscribe") }
    }
    var defaultExportFormat: ExportFormat {
        didSet { UserDefaults.standard.set(defaultExportFormat.rawValue, forKey: "defaultExportFormat") }
    }

    init() {
        self.autoTranscribe = UserDefaults.standard.bool(forKey: "autoTranscribe")
        let formatRaw = UserDefaults.standard.string(forKey: "defaultExportFormat") ?? "md"
        self.defaultExportFormat = ExportFormat(rawValue: formatRaw) ?? .markdown
    }
}
