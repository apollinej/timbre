import SwiftUI

/// Home button for top-left of every non-home view
struct HomeButton: View {
    let action: () -> Void

    var body: some View {
        BubbleButton(
            icon: "house.fill",
            size: 30,
            color: Color(hex: "0088FF"),
            action: action
        )
    }
}
