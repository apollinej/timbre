import SwiftUI

struct SettingsView: View {
    @State private var modelManager = ModelManager()
    @AppStorage("autoTranscribe") private var autoTranscribe = false
    @State private var storagePath = TimbrePaths.rootPath
    @State private var storageError = false

    var body: some View {
        Form {
            Section {
                Picker("model", selection: $modelManager.selectedModel) {
                    ForEach(WhisperModel.allCases) { model in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                                .font(TimbreFont.font(size: 12))
                            Text(model.description)
                                .font(TimbreFont.font(size: 9))
                                .foregroundStyle(Color(hex: "0088C8"))
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("transcription model")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "044060"))
            }

            Section {
                Toggle("auto-transcribe on import", isOn: $autoTranscribe)
                    .font(TimbreFont.font(size: 12))
            } header: {
                Text("import")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "044060"))
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(storagePath)
                            .font(TimbreFont.font(size: 11))
                            .foregroundStyle(Color(hex: "044060"))
                            .lineLimit(2)
                            .truncationMode(.middle)

                        Spacer()

                        Button("change\u{2026}") { pickStorageFolder() }
                            .font(TimbreFont.font(size: 11))
                            .buttonStyle(.plain)
                            .foregroundStyle(Color(hex: "0088FF"))
                    }

                    if storagePath != TimbrePaths.defaultRootPath {
                        Button("reset to default") {
                            TimbrePaths.resetToDefault()
                            storagePath = TimbrePaths.rootPath
                        }
                        .font(TimbreFont.font(size: 10))
                        .buttonStyle(.plain)
                        .foregroundStyle(Color(hex: "0088C8"))
                    }

                    if storageError {
                        Text("folder is not writable. pick a different one.")
                            .font(TimbreFont.font(size: 10))
                            .foregroundStyle(Color(hex: "FF4060"))
                    }
                }
            } header: {
                Text("storage location")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "044060"))
            } footer: {
                Text("audio files, transcripts, and the database are stored here.")
                    .font(TimbreFont.font(size: 9))
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
        .formStyle(.grouped)
        .tint(Color(hex: "0088FF"))
        .scrollContentBackground(.hidden)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "F0FCFF"),
                        Color(hex: "C8E8FF"),
                        Color(hex: "E0FFF8"),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                SubtleScanlines()
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.7), Color(hex: "00C8FF").opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .padding(4)
        )
        .frame(width: 480, height: 420)
        .textCase(.lowercase)
    }

    private func pickStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Pick where timbre stores files"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        if TimbrePaths.setRoot(url.path) {
            storagePath = TimbrePaths.rootPath
            storageError = false
            try? TimbrePaths.prepareStorageDirectories()
        } else {
            storageError = true
        }
    }
}
