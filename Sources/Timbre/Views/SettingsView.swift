import SwiftUI

struct SettingsView: View {
    @State private var modelManager = ModelManager()
    @AppStorage("autoTranscribe") private var autoTranscribe = false

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
        .frame(width: 450, height: 300)
        .textCase(.lowercase)
    }
}
