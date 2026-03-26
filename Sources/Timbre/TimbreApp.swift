import SwiftUI
import SwiftData

@main
struct TimbreApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        TimbreFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ChromeWindow {
                ContentView()
            }
            .ignoresSafeArea()
        }
        .modelContainer(for: [Folder.self, Memo.self, Transcript.self, Segment.self, Speaker.self])
        .defaultSize(width: 960, height: 620)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.isOpaque = true
                window.backgroundColor = NSColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1)
                window.hasShadow = true
            }
        }
    }
}
