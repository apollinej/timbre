import SwiftUI

// MARK: - Menu Data Types

struct TimbreMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String?
    let isDestructive: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
}

enum TimbreMenuEntry: Identifiable {
    case item(TimbreMenuItem)
    case divider
    case section(String, [TimbreMenuItem])

    var id: String {
        switch self {
        case .item(let item): return item.id.uuidString
        case .divider: return UUID().uuidString
        case .section(let title, _): return "section-\(title)"
        }
    }
}

// MARK: - Right Click Detection (NSViewRepresentable)

struct RightClickCatcher: NSViewRepresentable {
    let onRightClick: (NSPoint) -> Void

    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.onRightClick = onRightClick
    }
}

class RightClickNSView: NSView {
    var onRightClick: ((NSPoint) -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard NSApp.currentEvent?.type == .rightMouseDown else { return nil }
        return super.hitTest(point)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(NSEvent.mouseLocation)
    }
}

// MARK: - Themed Menu Panel

final class TimbreMenuPanel {
    static let shared = TimbreMenuPanel()
    private var panel: NSPanel?
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    func show(entries: [TimbreMenuEntry]) {
        dismiss()

        let menuView = TimbreMenuContent(entries: entries) { [weak self] in
            self?.dismiss()
        }

        let hosting = NSHostingView(rootView: menuView)
        hosting.setFrameSize(hosting.fittingSize)

        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .popUpMenu
        p.contentView = hosting
        p.hasShadow = false

        var origin = NSEvent.mouseLocation
        origin.y -= hosting.fittingSize.height
        p.setFrame(NSRect(origin: origin, size: hosting.fittingSize), display: true)
        p.orderFront(nil)
        self.panel = p

        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let panel = self?.panel, !panel.frame.contains(NSEvent.mouseLocation) {
                self?.dismiss()
            }
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.dismiss() }
            return event
        }
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - Menu Content View

private struct TimbreMenuContent: View {
    let entries: [TimbreMenuEntry]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entries) { entry in
                switch entry {
                case .item(let item):
                    menuItemView(item)
                case .divider:
                    Rectangle()
                        .fill(Color(hex: "00B0FF").opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                case .section(let header, let items):
                    Text(header.lowercased())
                        .font(Theme.captionFont)
                        .foregroundStyle(Color(hex: "0088C8"))
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                    ForEach(items) { item in menuItemView(item) }
                }
            }
        }
        .padding(.vertical, 6)
        .frame(minWidth: 190)
        .background(menuBackground)
    }

    private func menuItemView(_ item: TimbreMenuItem) -> some View {
        TimbreMenuItemView(item: item) {
            item.action()
            onDismiss()
        }
    }

    private var menuBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "F0FCFF").opacity(0.97),
                        Color(hex: "D4EEFF").opacity(0.97),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color(hex: "00B0FF").opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color(hex: "0080C0").opacity(0.25), radius: 12, y: 4)
            .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
    }
}

// MARK: - Single Menu Item

private struct TimbreMenuItemView: View {
    let item: TimbreMenuItem
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 16)
                }
                Text(item.title.lowercased())
                    .font(TimbreFont.fontBold(size: 12))
                Spacer()
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                isHovered
                    ? LinearGradient(
                        colors: [Color(hex: "00B8FF").opacity(0.25), Color(hex: "00D0FF").opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    )
                    : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var foregroundColor: Color {
        if item.isDestructive { return Color(hex: "FF4080") }
        return isHovered ? Color(hex: "0060A0") : Color(hex: "044060")
    }
}

// MARK: - View Modifier

extension View {
    func timbreContextMenu(entries: @escaping () -> [TimbreMenuEntry]) -> some View {
        self
            .overlay(
                RightClickCatcher { _ in
                    TimbreMenuPanel.shared.show(entries: entries())
                }
            )
    }
}
