import Foundation

#if canImport(SQLite3)
import SQLite3
#endif

/// On-device SQLite cache for SEQTA student payloads (JSON blobs per scope + key).
actor StudentLocalDatabase {
    private let fileManager: FileManager
    #if canImport(SQLite3)
    private var db: OpaquePointer?
    #endif

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadData(scope: String, key: String) -> Data? {
        #if canImport(SQLite3)
        openDatabaseIfNeeded()
        guard let db else { return nil }
        let sql = "SELECT payload FROM cache_entries WHERE scope = ? AND key = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, scope, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, key, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        guard let bytes = sqlite3_column_blob(statement, 0) else { return nil }
        let length = Int(sqlite3_column_bytes(statement, 0))
        return Data(bytes: bytes, count: length)
        #else
        return nil
        #endif
    }

    func save(scope: String, key: String, data: Data) {
        #if canImport(SQLite3)
        openDatabaseIfNeeded()
        guard let db else { return }
        let sql = """
        INSERT INTO cache_entries(scope, key, payload, updated_at)
        VALUES(?, ?, ?, ?)
        ON CONFLICT(scope, key) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, scope, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, key, -1, SQLITE_TRANSIENT)
        data.withUnsafeBytes { raw in
            _ = sqlite3_bind_blob(statement, 3, raw.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
        }
        sqlite3_bind_double(statement, 4, Date().timeIntervalSince1970)
        _ = sqlite3_step(statement)
        #endif
    }

    func removeKeys(matchingPrefix prefix: String, scope: String) {
        #if canImport(SQLite3)
        openDatabaseIfNeeded()
        guard let db else { return }
        let sql = "DELETE FROM cache_entries WHERE scope = ? AND key LIKE ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, scope, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, "\(prefix)%", -1, SQLITE_TRANSIENT)
        _ = sqlite3_step(statement)
        #endif
    }

    func clear(scope: String) {
        #if canImport(SQLite3)
        openDatabaseIfNeeded()
        guard let db else { return }
        let sql = "DELETE FROM cache_entries WHERE scope = ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, scope, -1, SQLITE_TRANSIENT)
        _ = sqlite3_step(statement)
        #endif
    }

    func clearAll() {
        #if canImport(SQLite3)
        openDatabaseIfNeeded()
        guard let db else { return }
        _ = sqlite3_exec(db, "DELETE FROM cache_entries;", nil, nil, nil)
        #endif
    }

    #if canImport(SQLite3)
    private func openDatabaseIfNeeded() {
        guard db == nil else { return }
        let url = databaseURL()
        try? fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            db = nil
            return
        }
        let create = """
        CREATE TABLE IF NOT EXISTS cache_entries(
          scope TEXT NOT NULL,
          key TEXT NOT NULL,
          payload BLOB NOT NULL,
          updated_at REAL NOT NULL,
          PRIMARY KEY(scope, key)
        );
        """
        _ = sqlite3_exec(db, create, nil, nil, nil)
    }

    private func databaseURL() -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("BetterSEQTA", isDirectory: true)
            .appendingPathComponent("student_cache.sqlite", isDirectory: false)
    }

    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    #endif
}
