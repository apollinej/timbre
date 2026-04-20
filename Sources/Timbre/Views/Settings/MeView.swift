import SwiftUI

struct MeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var keySaved = false
    @State private var keyError: String?

    var body: some View {
        ZStack {
            Theme.iridescentSubtle.ignoresSafeArea()
            SubtleScanlines()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 20) {
                        aiProviderSection
                        apiKeySection
                        aboutSection
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 400)
        .onAppear {
            apiKey = KeychainService.read(key: "openai-api-key") ?? ""
        }
    }

    private var header: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "A8D8F8"), intensity: 0.3)
            HStack {
                Text("settings")
                    .font(TimbreFont.fontBold(size: 22))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 48)
    }

    private var aiProviderSection: some View {
        sectionCard("ai provider") {
            HStack {
                Text("model")
                    .font(TimbreFont.font(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text("openai gpt-4o")
                    .font(TimbreFont.fontBold(size: 14))
                    .foregroundStyle(Color(hex: "0088FF"))
            }
        }
    }

    private var apiKeySection: some View {
        sectionCard("api key") {
            VStack(alignment: .leading, spacing: 10) {
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(hex: "0080C0").opacity(0.3))
                    )

                HStack {
                    TimbrePill("save key", style: .primary) { saveKey() }

                    if keySaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("saved")
                                .font(TimbreFont.font(size: 12))
                                .foregroundStyle(.green)
                        }
                    }

                    if let err = keyError {
                        Text(err)
                            .font(TimbreFont.font(size: 12))
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }

                Text("your key is stored locally in keychain, never transmitted except to openai")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
    }

    private var aboutSection: some View {
        sectionCard("about") {
            HStack {
                Text("timbre")
                    .font(TimbreFont.fontBold(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Text("v3.0")
                    .font(TimbreFont.font(size: 14))
                    .foregroundStyle(Color(hex: "2090C8"))
            }
        }
    }

    private func sectionCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(TimbreFont.fontBold(size: 16))
                .foregroundStyle(Color(hex: "0088FF"))

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(hex: "40C8FF").opacity(0.25))
        )
    }

    private func saveKey() {
        keySaved = false
        keyError = nil
        do {
            if apiKey.isEmpty {
                KeychainService.delete(key: "openai-api-key")
            } else {
                try KeychainService.save(key: "openai-api-key", value: apiKey)
            }
            keySaved = true
        } catch {
            keyError = error.localizedDescription
        }
    }
}
