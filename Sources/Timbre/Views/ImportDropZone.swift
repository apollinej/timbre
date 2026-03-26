import SwiftUI

struct ImportDropZone: View {
    var body: some View {
        ZStack {
            Theme.iridescentLilac.opacity(0.15)
                .ignoresSafeArea()

            Rectangle()
                .strokeBorder(
                    Theme.accent,
                    style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                )
                .padding(16)

            VStack(spacing: 8) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.accent)

                Text("DROP TO IMPORT")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.accent)
            }
        }
        .allowsHitTesting(false)
    }
}
