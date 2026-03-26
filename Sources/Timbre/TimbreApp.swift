import SwiftUI
import SwiftData

@main
struct TimbreApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ChromeWindow {
                ContentView()
            }
            .ignoresSafeArea()
        }
        .modelContainer(for: [Folder.self, Memo.self, Transcript.self, Segment.self, Speaker.self])
        .defaultSize(width: 880, height: 580)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.isOpaque = true
                window.backgroundColor = NSColor(red: 0.72, green: 0.75, blue: 0.82, alpha: 1)
                window.hasShadow = true
            }
        }
    }
}
