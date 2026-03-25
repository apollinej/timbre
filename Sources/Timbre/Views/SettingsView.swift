import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Transcription Model") {
                Picker("Model", selection: Binding(
                    get: { viewModel.modelManager.selectedModel },
                    set: { viewModel.modelManager.selectModel($0) }
                )) {
                    ForEach(WhisperModel.allCases) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                Text(model.sizeDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if model.requiresHighRAM {
                                Text("16GB+ RAM")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.yellow.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Behavior") {
                Toggle("Auto-transcribe on import", isOn: $viewModel.autoTranscribe)
            }

            Section("Export") {
                Picker("Default format", selection: $viewModel.defaultExportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 350)
    }
}
