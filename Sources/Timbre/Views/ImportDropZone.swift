import SwiftUI

struct ImportDropZone: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "00FFFF").opacity(0.12),
                    Color(hex: "0088FF").opacity(0.1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "00D8FF"), Color(hex: "00FF88")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                )
                .padding(16)

            VStack(spacing: 10) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "0088FF"), Color(hex: "00FFAA")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("drop to import")
                    .font(TimbreFont.fontBold(size: 20))
                    .foregroundStyle(Color(hex: "0080E0"))

                HStack(spacing: 6) {
                    PixelStar(color: Color(hex: "00FFFF"))
                    PixelStar(color: Color(hex: "00FF88"))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
