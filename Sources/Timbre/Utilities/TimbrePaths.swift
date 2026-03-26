import Foundation

/// All Timbre user data lives under a configurable root directory.
/// Default: `~/Desktop/apolline-production/timbre/`
/// User can change via Settings.
enum TimbrePaths {
    private static let defaultRoot = "Desktop/apolline-production/timbre"
    private static let rootKey = "timbreStorageRoot"

    /// User-configurable storage root. Persisted in UserDefaults.
    static var root: URL {
        if let custom = UserDefaults.standard.string(forKey: rootKey),
           !custom.isEmpty {
            let url = URL(fileURLWithPath: custom, isDirectory: true)
            if FileManager.default.isWritableFile(atPath: url.path) {
                return url
            }
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(defaultRoot, isDirectory: true)
    }

    /// Set a new storage root. Returns false if the path isn't writable.
    @discardableResult
    static func setRoot(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        // Create if needed
        try? FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true
        )
        guard FileManager.default.isWritableFile(atPath: url.path) else {
            return false
        }
        UserDefaults.standard.set(path, forKey: rootKey)
        return true
    }

    /// Reset to default location.
    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: rootKey)
    }

    /// Copied voice memo files
    static var library: URL {
        root.appendingPathComponent("library", isDirectory: true)
    }

    /// Plain-text transcript mirrors (one `.txt` per memo id).
    static var transcripts: URL {
        root.appendingPathComponent("transcripts", isDirectory: true)
    }

    /// SwiftData store file
    static var databaseStoreURL: URL {
        root.appendingPathComponent("timbre.store", isDirectory: false)
    }

    /// WhisperKit model cache
    static var modelCache: URL {
        root.appendingPathComponent("models", isDirectory: true)
    }

    /// Creates all required subdirectories.
    static func prepareStorageDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
        try fm.createDirectory(at: transcripts, withIntermediateDirectories: true)
        try fm.createDirectory(at: modelCache, withIntermediateDirectories: true)
    }

    /// Human-readable path for display.
    static var rootPath: String { root.path }

    /// Default root path for display.
    static var defaultRootPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(defaultRoot, isDirectory: true)
            .path
    }
}
