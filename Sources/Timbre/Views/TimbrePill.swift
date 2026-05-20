import SwiftUI

/// Standardized pill button used across all sheets and prompts.
struct TimbrePill: View {
    let label: String
    let style: Style
    let action: () -> Void

    enum Style {
        case primary    // filled blue
        case secondary  // outlined light
    }

    init(_ label: String, style: Style, action: @escaping () -> Void) {
        self.label = label
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TimbreFont.fontBold(size: 13))
                .foregroundStyle(style == .primary ? .white : Color(hex: "0088FF"))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(pillBackground)
                .overlay(pillBorder)
                .shadow(color: Color(hex: "00C8FF").opacity(0.2), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var pillBackground: some View {
        Capsule().fill(
            style == .primary
                ? LinearGradient(
                    colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                    startPoint: .top, endPoint: .bottom
                )
                : LinearGradient(
                    colors: [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                    startPoint: .top, endPoint: .bottom
                )
        )
    }

    private var pillBorder: some View {
        Capsule().strokeBorder(
            style == .primary
                ? Color.white.opacity(0.45)
                : Color(hex: "0080C0").opacity(0.35),
            lineWidth: 1
        )
    }
}

/// Light-blue action pill matching the decode-page headerPill style
/// (light gradient, darker text, glossy border). Used for the
/// "prompt" / "edit" / "export" / etc. actions in the side panel.
struct TimbreActionPill: View {
    let icon: String
    let label: String
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isBusy {
                    ProgressView().controlSize(.small).tint(Color(hex: "0088FF"))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(isBusy ? "analyzing\u{2026}" : label)
                    .font(TimbreFont.fontBold(size: 12))
            }
            .foregroundStyle(Color(hex: "0088FF"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            )
            .overlay(
                Capsule().strokeBorder(Color(hex: "0080C0").opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color(hex: "00C8FF").opacity(0.15), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}

/// Sparkle-prefixed action pill — light blue to signal actionable.
struct TimbrePromptPill: View {
    let label: String
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        TimbreActionPill(icon: "sparkles", label: label, isBusy: isBusy, action: action)
    }
}

/// Pencil-prefixed action pill — light blue, for editing existing analysis.
struct TimbreEditPill: View {
    let label: String
    let action: () -> Void

    var body: some View {
        TimbreActionPill(icon: "pencil", label: label, isBusy: false, action: action)
    }
}

/// Toggle pill for filters — matches TimbrePill style but with selected/unselected state
struct TimbreTogglePill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TimbreFont.fontBold(size: 12))
                .foregroundStyle(isSelected ? .white : Color(hex: "0088FF"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        isSelected
                            ? LinearGradient(
                                colors: [Color(hex: "00B8FF"), Color(hex: "0080E0")],
                                startPoint: .top, endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                                startPoint: .top, endPoint: .bottom
                            )
                    )
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected
                            ? Color.white.opacity(0.45)
                            : Color(hex: "0080C0").opacity(0.35),
                        lineWidth: 1
                    )
                )
                .shadow(color: Color(hex: "00C8FF").opacity(0.15), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// Person filter chip — colored by person
struct TimbrePersonChip: View {
    let person: Person
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        TimbreColoredChip(
            label: person.canonicalName.lowercased(),
            colorHex: person.colorHex,
            isSelected: isSelected,
            action: action
        )
    }
}

/// Generic colored filter chip — for any (label, color) pair.
struct TimbreColoredChip: View {
    let label: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(TimbreFont.fontBold(size: 11))
                    .foregroundStyle(isSelected ? .white : Color(hex: "044060"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(
                    isSelected
                        ? AnyShapeStyle(Color(hex: colorHex).opacity(0.8))
                        : AnyShapeStyle(Color(hex: "E8F4FF"))
                )
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected
                        ? Color(hex: colorHex)
                        : Color(hex: "0080C0").opacity(0.35),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}
