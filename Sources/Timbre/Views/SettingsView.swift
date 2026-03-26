import SwiftUI

struct SettingsView: View {
    @State private var modelManager = ModelManager()
    @AppStorage("autoTranscribe") private var autoTranscribe = false

    var body: some View {
        Form {
            Section("Transcription Model") {
                Picker("Model", selection: $modelManager.selectedModel) {
                    ForEach(WhisperModel.allCases) { model in
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                            Text(model.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Import") {
                Toggle("Auto-transcribe on import", isOn: $autoTranscribe)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 300)
    }
}
