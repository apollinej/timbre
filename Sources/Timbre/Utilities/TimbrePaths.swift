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

    /// Plain-text transcript mirrors (one `.txt` per memo id).
    static var transcripts: URL {
        root.appendingPathComponent("transcripts", isDirectory: true)
    }

    /// SwiftData store file (memos, folders, transcripts, segments, speakers, renames).
    static var databaseStoreURL: URL {
        root.appendingPathComponent("timbre.store", isDirectory: false)
    }

    /// Creates `timbre/`, `library/`, and `transcripts/` if missing.
    static func prepareStorageDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
        try fm.createDirectory(at: transcripts, withIntermediateDirectories: true)
    }

    /// Human-readable path for About / debugging.
    static var rootPath: String { root.path }
}
