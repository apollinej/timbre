import Foundation

/// All Timbre user data lives under `~/Desktop/apolline-production/timbre/`.
enum TimbrePaths {
    private static let rootFolderName = "apolline-production"
    private static let timbreFolderName = "timbre"

    /// `~/Desktop/apolline-production/timbre`
    static var root: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
            .appendingPathComponent(rootFolderName, isDirectory: true)
            .appendingPathComponent(timbreFolderName, isDirectory: true)
    }

    /// Copied voice memo files (`~/Desktop/.../timbre/library`)
    static var library: URL {
        root.appendingPathComponent("library", isDirectory: true)
    }

    /// SwiftData store file (memos, folders, transcripts, segments, speakers, renames).
    static var databaseStoreURL: URL {
        root.appendingPathComponent("timbre.store", isDirectory: false)
    }

    /// Creates `timbre/` and `timbre/library/` if missing.
    static func prepareStorageDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
    }

    /// Human-readable path for About / debugging.
    static var rootPath: String { root.path }
}
