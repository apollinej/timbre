import SwiftUI

struct RecordPostSavePrompt: View {
    let onAnalyze: () -> Void
    let onRecordAnother: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("memo saved")
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "004878"))

            // TODO: whimsy — celebration sparkle here

            HStack(spacing: 12) {
                promptPill("decode", isPrimary: true, action: onAnalyze)
                promptPill("record another", isPrimary: false, action: onRecordAnother)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.chromeGradient)
        )
    }

    private func promptPill(
        _ label: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isPrimary {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(TimbreFont.fontBold(size: 13))
            }
            .foregroundStyle(isPrimary ? .white : Color(hex: "0088FF"))
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(
                    isPrimary
                        ? LinearGradient(
                            colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                            startPoint: .top, endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.95), Color(hex: "C8F0FF")],
                            startPoint: .top, endPoint: .bottom
                        )
                )
            )
            .overlay(
                Capsule().strokeBorder(
                    isPrimary
                        ? Color.white.opacity(0.45)
                        : Color(hex: "00B0FF").opacity(0.6),
                    lineWidth: 1.5
                )
            )
            .shadow(
                color: Color(hex: "00C8FF").opacity(0.25),
                radius: 4, y: 2
            )
        }
        .buttonStyle(.plain)
    }
}
