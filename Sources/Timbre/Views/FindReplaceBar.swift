import SwiftUI

struct FindReplaceBar: View {
    @Binding var findText: String
    @Binding var replaceText: String
    let onReplaceAll: () -> Void
    let onClose: () -> Void
    @FocusState private var findFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "0088C8"))

                TextField("find", text: $findText)
                    .textFieldStyle(.plain)
                    .font(TimbreFont.font(size: 13))
                    .focused($findFocused)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "0088C8"))

                TextField("replace with", text: $replaceText)
                    .textFieldStyle(.plain)
                    .font(TimbreFont.font(size: 13))

                Button {
                    onReplaceAll()
                } label: {
                    Text("replace all")
                        .font(TimbreFont.fontBold(size: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(findText.isEmpty)

                Button { onClose() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Color(hex: "40C8FF").opacity(0.35))
                .frame(height: 1)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "E0F8FF"), Color(hex: "D0ECFF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear { findFocused = true }
    }
}
