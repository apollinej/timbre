import SwiftUI

struct ImportDropZone: View {
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.05)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 3, dash: [12, 8])
                )
                .padding(24)

            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                Text("Drop audio files to import")
                    .font(.title2)
                    .foregroundStyle(.accent)
            }
        }
        .allowsHitTesting(false)
    }
}
