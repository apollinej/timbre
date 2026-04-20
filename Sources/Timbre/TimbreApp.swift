import SwiftUI
import SwiftData

@main
struct TimbreApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let modelContainer: ModelContainer

    init() {
        TimbreFont.register()

        do {
            try TimbreMigration.migrateLegacyStoreIfNeeded()
            try TimbrePaths.prepareStorageDirectories()
            let schema = Schema([
                Folder.self,
                Memo.self,
                Transcript.self,
                Segment.self,
                Speaker.self,
                Person.self,
                MemoAnalysis.self,
                AnalysisItem.self,
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                url: TimbrePaths.databaseStoreURL
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Timbre could not open storage at \(TimbrePaths.rootPath): \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ChromeWindow {
                ContentView()
            }
            .ignoresSafeArea()
        }
        .modelContainer(modelContainer)
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
