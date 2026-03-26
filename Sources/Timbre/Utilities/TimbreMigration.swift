import Foundation
import SQLite3

/// One-time copy of the pre–Desktop-store SwiftData database from Application Support.
enum TimbreMigration {
    private static let migratedKey = "timbre.migratedLegacyApplicationSupportStore.v2"

    /// `~/Library/Application Support/default.store` (SwiftData default before a custom URL).
    private static var legacyApplicationSupportStore: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("default.store", isDirectory: false)
    }

    /// Run before opening `ModelContainer`. Copies legacy Timbre data if the Desktop store is missing or empty.
    static func migrateLegacyStoreIfNeeded() throws {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: migratedKey) { return }

        let fm = FileManager.default
        let legacy = legacyApplicationSupportStore
        guard fm.fileExists(atPath: legacy.path), isTimbreSwiftDataStore(at: legacy) else {
            return
        }

        let dest = TimbrePaths.databaseStoreURL
        let legacyMemoCount = sqliteMemoCount(at: legacy) ?? 0
        guard legacyMemoCount > 0 else {
            defaults.set(true, forKey: migratedKey)
            return
        }

        let destCount = fm.fileExists(atPath: dest.path) ? (sqliteMemoCount(at: dest) ?? 0) : 0

        if destCount > 0 {
            defaults.set(true, forKey: migratedKey)
            return
        }

        try TimbrePaths.prepareStorageDirectories()
        try removeSQLiteStoreBundle(at: dest)
        try copySQLiteStoreBundle(from: legacy, to: dest)
        defaults.set(true, forKey: migratedKey)
    }

    private static func isTimbreSwiftDataStore(at url: URL) -> Bool {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, db != nil else {
            return false
        }
        defer { sqlite3_close(db) }

        let sql = "SELECT 1 FROM sqlite_master WHERE type='table' AND name='ZMEMO' LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW
    }

    private static func sqliteMemoCount(at storeURL: URL) -> Int? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, db != nil else {
            return nil
        }
        defer { sqlite3_close(db) }

        let sql = "SELECT COUNT(*) FROM ZMEMO"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int64(stmt, 0))
    }

    private static func removeSQLiteStoreBundle(at base: URL) throws {
        let fm = FileManager.default
        let dir = base.deletingLastPathComponent()
        let leaf = base.lastPathComponent
        for suffix in ["", "-shm", "-wal"] {
            let url = dir.appendingPathComponent(leaf + suffix)
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
        }
    }

    private static func copySQLiteStoreBundle(from sourceBase: URL, to destBase: URL) throws {
        let fm = FileManager.default
        let srcDir = sourceBase.deletingLastPathComponent()
        let dstDir = destBase.deletingLastPathComponent()
        let srcLeaf = sourceBase.lastPathComponent
        let dstLeaf = destBase.lastPathComponent
        for suffix in ["", "-shm", "-wal"] {
            let src = srcDir.appendingPathComponent(srcLeaf + suffix)
            let dst = dstDir.appendingPathComponent(dstLeaf + suffix)
            guard fm.fileExists(atPath: src.path) else { continue }
            if fm.fileExists(atPath: dst.path) {
                try fm.removeItem(at: dst)
            }
            try fm.copyItem(at: src, to: dst)
        }
    }
}
