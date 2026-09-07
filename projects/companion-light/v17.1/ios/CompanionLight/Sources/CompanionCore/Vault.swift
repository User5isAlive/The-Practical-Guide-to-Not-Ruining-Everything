// CC0-1.0
// The Vault: append-only, hash-chained event log with materialized current state, one SQLite file.
//
// v17.1 changes, by ledger ID:
//   CAT-009  payloads encrypted under a per-object key; the chain commits to CIPHERTEXT + provenance
//   CAT-010  no trust parameter: ingestOwner / ingestLocal / ingestFrontier / ingestExternal
//   CAT-013  access record keeps older_sum (sufficient statistic for mean evicted age)
//   CAT-016  shred() deletes the wrapped key and tombstones the OBJECTS row; the EVENTS row is never touched
//   CAT-018  owner signature is bound to the event hash (prev_hash+seq inside), so it cannot be replayed;
//            T1-A elevation (promote, sliders, shred) requires a fresh-presence token from PresenceGate
//   CAT-019  the vault holds the owner's key; it never accepts a public key as an argument
import Foundation

public enum VaultError: Error { case sql(String), chainBroken(Int), notFound(String), trustViolation(String), presenceRequired(String), shredded(String) }

public struct AccessRecord: Codable {
    public var createdAt: Double
    public var recent: [Double] = []
    public var olderCount: Int = 0
    public var olderSum: Double = 0          // CAT-013: sum of evicted timestamps
    public mutating func touch(_ when: Double, maxExact: Int = 20) {
        recent.append(when)
        if recent.count > maxExact { let evicted = recent.removeFirst(); olderCount += 1; olderSum += evicted }
    }
}

public struct Event { public let seq: Int; public let id: String; public let kind: String; public let subject: String; public let provenance: String; public let ciphertext: Data; public let prevHash: String; public let hash: String; public let sig: String? }

/// CAT-018. A T1-A action needs the owner present *now*. Production: LocalAuthentication / BiometricPrompt.
public protocol PresenceGate { func requirePresence(reason: String) async throws -> PresenceToken }
public struct PresenceToken { public let nonce: String; public let issuedAt: Double; public init(nonce: String, issuedAt: Double) { self.nonce = nonce; self.issuedAt = issuedAt } }

/// Holds the master wrapping key. Production: Secure Enclave / Keychain. Test: in-memory.
public protocol KeyStore { func masterKey() throws -> SymmetricKey }
public struct EphemeralKeyStore: KeyStore { let k = SymmetricKey(size: .bits256); public init() {}; public func masterKey() throws -> SymmetricKey { k } }

public final class Vault {
    private var db: OpaquePointer?
    private let signer: Curve25519.Signing.PrivateKey      // owner root key — CAT-019: lives here, never passed in per call
    private let keys: KeyStore
    private let presence: PresenceGate?
    private var spentPresence: Set<String> = []
    public let ownerPublicKey: Data

    private static let signedKinds: Set<String> = ["OBJECT_CREATED_T1", "PROMOTION", "SLIDER", "CAPABILITY", "SHRED"]
    private static let presenceKinds: Set<String> = ["PROMOTION", "SLIDER", "CAPABILITY", "SHRED"]   // T1-A

    public init(path: String, signer: Curve25519.Signing.PrivateKey, keys: KeyStore = EphemeralKeyStore(), presence: PresenceGate? = nil) throws {
        self.signer = signer; self.keys = keys; self.presence = presence
        self.ownerPublicKey = signer.publicKey.rawRepresentation
        guard sqlite3_open(path, &db) == SQLITE_OK else { throw VaultError.sql("open") }
        try exec("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")
        try exec("""
        CREATE TABLE IF NOT EXISTS events(seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT UNIQUE, kind TEXT, subject TEXT,
            provenance TEXT, ciphertext BLOB, prev_hash TEXT, hash TEXT, sig TEXT);
        CREATE TABLE IF NOT EXISTS wrapped_keys(event_id TEXT PRIMARY KEY, wrapped BLOB);
        CREATE TABLE IF NOT EXISTS objects(id TEXT PRIMARY KEY, trust TEXT, source TEXT, text TEXT, created_at REAL,
            shelf TEXT, embedding BLOB, stub TEXT, tombstone INT DEFAULT 0);
        CREATE TABLE IF NOT EXISTS access(object_id TEXT PRIMARY KEY, created_at REAL, recent TEXT, older_count INT, older_sum REAL);
        CREATE TABLE IF NOT EXISTS receipts(id TEXT PRIMARY KEY, ts REAL, json TEXT);
        CREATE TABLE IF NOT EXISTS sliders(name TEXT PRIMARY KEY, value INT, ts REAL);
        """)
    }
    deinit { sqlite3_close(db) }

    // MARK: - Event log ------------------------------------------------------

    /// Every payload is sealed under a fresh per-object key (CAT-009). The hash commits to ciphertext, provenance
    /// and position (CAT-018), so nothing about an event can change without breaking the chain.
    @discardableResult
    func append(kind: String, subject: String, provenance: Trust?, payload: [String: Any], presenceToken: PresenceToken? = nil) throws -> Event {
        if Self.presenceKinds.contains(kind) {
            guard let t = presenceToken, !spentPresence.contains(t.nonce) else { throw VaultError.presenceRequired(kind) }
            spentPresence.insert(t.nonce)
        }
        let plain = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let objKey = SymmetricKey(size: .bits256)
        let ciphertext = try AES.GCM.seal(plain, using: objKey).combined!
        let wrapped = try AES.GCM.seal(objKey.withUnsafeBytes { Data($0) }, using: try keys.masterKey()).combined!
        let prev = try lastHash()
        let seq = try nextSeq()
        let prov = provenance?.rawValue ?? "-"
        let hash = Self.commit(prev: prev, seq: seq, kind: kind, subject: subject, provenance: prov, ciphertext: ciphertext)
        let sig: String? = Self.signedKinds.contains(kind) ? try signer.signature(for: Data(hash.utf8)).base64EncodedString() : nil
        let id = UUID().uuidString
        try exec("BEGIN")
        do {
            try run("INSERT INTO events(id,kind,subject,provenance,ciphertext,prev_hash,hash,sig) VALUES(?,?,?,?,?,?,?,?)",
                    [id, kind, subject, prov, ciphertext, prev, hash, sig as Any])
            try run("INSERT INTO wrapped_keys(event_id,wrapped) VALUES(?,?)", [id, wrapped])
            try materialize(kind: kind, subject: subject, payload: payload)
            try exec("COMMIT")
        } catch { try? exec("ROLLBACK"); throw error }
        return Event(seq: seq, id: id, kind: kind, subject: subject, provenance: prov, ciphertext: ciphertext, prevHash: prev, hash: hash, sig: sig)
    }

    static func commit(prev: String, seq: Int, kind: String, subject: String, provenance: String, ciphertext: Data) -> String {
        sha256(prev + "|" + String(seq) + "|" + kind + "|" + subject + "|" + provenance + "|" + ciphertext.base64EncodedString())
    }

    private func materialize(kind: String, subject: String, payload: [String: Any]) throws {
        switch kind {
        case "OBJECT_CREATED_T1", "OBJECT_CREATED_T2", "OBJECT_CREATED_T3", "OBJECT_CREATED_T4":
            try run("INSERT INTO objects(id,trust,source,text,created_at,shelf) VALUES(?,?,?,?,?,'resident')",
                    [subject, payload["trust"] as! String, payload["source"] as! String, payload["text"] as! String, payload["created_at"] as! Double])
            try run("INSERT INTO access(object_id,created_at,recent,older_count,older_sum) VALUES(?,?,'[]',0,0)", [subject, payload["created_at"] as! Double])
        case "FOLD":
            switch payload["after"] as! String {
            case "cold":   try run("UPDATE objects SET shelf='cold', embedding=NULL WHERE id=?", [subject])
            case "orphan": try run("UPDATE objects SET shelf='orphan', embedding=NULL, text=NULL, stub=? WHERE id=?", [payload["stub"] as! String, subject])
            default:       try run("UPDATE objects SET shelf='resident' WHERE id=?", [subject])
            }
        case "REHYDRATE": try run("UPDATE objects SET shelf='resident', text=?, stub=NULL WHERE id=?", [payload["text"] as! String, subject])
        case "SLIDER":    try run("INSERT INTO sliders(name,value,ts) VALUES(?,?,?) ON CONFLICT(name) DO UPDATE SET value=excluded.value, ts=excluded.ts",
                                  [subject, payload["value"] as! Int, Date().timeIntervalSince1970])
        case "RECEIPT":   try run("INSERT INTO receipts(id,ts,json) VALUES(?,?,?)", [subject, Date().timeIntervalSince1970, payload["json"] as! String])
        case "SHRED":     try run("UPDATE objects SET text=NULL, embedding=NULL, stub=NULL, tombstone=1 WHERE id=?", [subject])   // CAT-016
        default: break
        }
    }

    /// Recompute every commitment; verify every signature against the vault-held owner key.
    public func verifyChain() throws -> Bool {
        var prev = "genesis"
        for e in try events() {
            guard e.prevHash == prev,
                  Self.commit(prev: prev, seq: e.seq, kind: e.kind, subject: e.subject, provenance: e.provenance, ciphertext: e.ciphertext) == e.hash
            else { throw VaultError.chainBroken(e.seq) }
            if let s = e.sig, let d = Data(base64Encoded: s) {
                guard signer.publicKey.isValidSignature(d, for: Data(e.hash.utf8)) else { throw VaultError.chainBroken(e.seq) }
            } else if Self.signedKinds.contains(e.kind) { throw VaultError.chainBroken(e.seq) }
            prev = e.hash
        }
        return true
    }

    public func events() throws -> [Event] {
        try query("SELECT seq,id,kind,subject,provenance,ciphertext,prev_hash,hash,sig FROM events ORDER BY seq") { s in
            Event(seq: Int(sqlite3_column_int64(s, 0)), id: col(s, 1), kind: col(s, 2), subject: col(s, 3), provenance: col(s, 4),
                  ciphertext: blob(s, 5), prevHash: col(s, 6), hash: col(s, 7), sig: sqlite3_column_type(s, 8) == SQLITE_NULL ? nil : col(s, 8))
        }
    }

    /// Decrypt an event payload. Throws `.shredded` if the key is gone — ciphertext still there, still committed.
    public func payload(of e: Event) throws -> [String: Any] {
        guard let wrapped = try query("SELECT wrapped FROM wrapped_keys WHERE event_id=?", [e.id], { blob($0, 0) }).first else { throw VaultError.shredded(e.id) }
        let raw = try AES.GCM.open(try AES.GCM.SealedBox(combined: wrapped), using: try keys.masterKey())
        let plain = try AES.GCM.open(try AES.GCM.SealedBox(combined: e.ciphertext), using: SymmetricKey(data: raw))
        return try JSONSerialization.jsonObject(with: plain) as! [String: Any]
    }

    private func lastHash() throws -> String { try query("SELECT hash FROM events ORDER BY seq DESC LIMIT 1") { col($0, 0) }.first ?? "genesis" }
    private func nextSeq() throws -> Int { (try query("SELECT COALESCE(MAX(seq),0) FROM events") { Int(sqlite3_column_int64($0, 0)) }.first ?? 0) + 1 }

    // MARK: - Typed ingest (CAT-010). No method takes a trust class. ---------------

    /// T1-O: entered through the owner's input path. Integrity-signed; no presence required.
    @discardableResult public func ingestOwner(_ text: String, now: Double = Date().timeIntervalSince1970) throws -> MAObject { try create(text, .t1, "owner", now) }
    @discardableResult public func ingestLocal(_ text: String, role: String, now: Double = Date().timeIntervalSince1970) throws -> MAObject { try create(text, .t2, "local:\(role)", now) }
    @discardableResult public func ingestFrontier(_ text: String, model: String, now: Double = Date().timeIntervalSince1970) throws -> MAObject { try create(text, .t3, "frontier:\(model)", now) }
    @discardableResult public func ingestExternal(_ text: String, origin: String, now: Double = Date().timeIntervalSince1970) throws -> MAObject { try create(text, .t4, "external:\(origin)", now) }

    private func create(_ text: String, _ trust: Trust, _ source: String, _ now: Double) throws -> MAObject {
        let id = UUID().uuidString
        try append(kind: "OBJECT_CREATED_\(trust.rawValue)", subject: id, provenance: trust,
                   payload: ["trust": trust.rawValue, "source": source, "text": text, "created_at": now])
        return MAObject(id: id, trust: trust, source: source, text: text, createdAt: now, shelf: .resident, embedding: nil, stub: nil)
    }

    /// T1-A: owner makes a signed statement ABOUT a T3/T4 object. Needs fresh presence. The object keeps its class.
    @discardableResult
    public func promote(about objectId: String, ownerStatement: String) async throws -> MAObject {
        let target = try object(objectId)
        guard target.trust != .t1 else { throw VaultError.trustViolation("already T1") }
        let token = try await requirePresence("promote \(objectId)")
        let stmt = try create(ownerStatement, .t1, "owner_about:\(objectId)", Date().timeIntervalSince1970)
        try append(kind: "PROMOTION", subject: stmt.id, provenance: .t1, payload: ["about": objectId, "about_trust": target.trust.rawValue], presenceToken: token)
        return stmt
    }

    /// T1-A: cryptographic erasure (CAT-009/016). Deletes the wrapped key for every event about this object and
    /// tombstones the materialized row. Event rows are untouched; the chain still verifies; the text is gone.
    public func shred(_ objectId: String) async throws {
        let token = try await requirePresence("erase \(objectId)")
        for e in try events() where e.subject == objectId { try run("DELETE FROM wrapped_keys WHERE event_id=?", [e.id]) }
        try append(kind: "SHRED", subject: objectId, provenance: .t1, payload: ["erased_at": Date().timeIntervalSince1970], presenceToken: token)
    }

    private func requirePresence(_ reason: String) async throws -> PresenceToken {
        guard let g = presence else { throw VaultError.presenceRequired(reason) }
        return try await g.requirePresence(reason: reason)
    }

    // MARK: - Objects --------------------------------------------------------

    public func object(_ id: String) throws -> MAObject {
        guard let o = try objects(where: "id=?", [id]).first else { throw VaultError.notFound(id) }
        return o
    }
    public func allObjects() throws -> [MAObject] { try objects(where: "tombstone=0", []) }

    private func objects(where clause: String, _ args: [Any]) throws -> [MAObject] {
        try query("SELECT id,trust,source,text,created_at,shelf,embedding,stub FROM objects WHERE \(clause)", args) { s in
            var emb: [Float]? = nil
            if sqlite3_column_type(s, 6) != SQLITE_NULL { emb = blob(s, 6).withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
            var stub: [String: String]? = nil
            if sqlite3_column_type(s, 7) != SQLITE_NULL { stub = try? JSONDecoder().decode([String: String].self, from: Data(col(s, 7).utf8)) }
            return MAObject(id: col(s, 0), trust: Trust(rawValue: col(s, 1))!, source: col(s, 2),
                            text: sqlite3_column_type(s, 3) == SQLITE_NULL ? nil : col(s, 3),
                            createdAt: sqlite3_column_double(s, 4), shelf: Shelf(rawValue: col(s, 5))!, embedding: emb, stub: stub)
        }
    }

    public func setEmbedding(_ id: String, _ v: [Float]) throws { try run("UPDATE objects SET embedding=? WHERE id=?", [v.withUnsafeBufferPointer { Data(buffer: $0) }, id]) }

    /// Orphan text is recovered from the log by decrypting — which fails, correctly, if the object was shredded.
    public func textFromLog(_ id: String) throws -> String? {
        for e in try events() where e.kind.hasPrefix("OBJECT_CREATED") && e.subject == id { return try payload(of: e)["text"] as? String }
        return nil
    }

    // MARK: - Access ---------------------------------------------------------

    public func access(_ id: String) throws -> AccessRecord {
        guard let r = try query("SELECT created_at,recent,older_count,older_sum FROM access WHERE object_id=?", [id], { s in
            AccessRecord(createdAt: sqlite3_column_double(s, 0), recent: (try? JSONDecoder().decode([Double].self, from: Data(col(s, 1).utf8))) ?? [],
                         olderCount: Int(sqlite3_column_int(s, 2)), olderSum: sqlite3_column_double(s, 3)) }).first
        else { throw VaultError.notFound(id) }
        return r
    }
    public func saveAccess(_ id: String, _ r: AccessRecord) throws {
        try run("UPDATE access SET recent=?, older_count=?, older_sum=? WHERE object_id=?", [String(data: try JSONEncoder().encode(r.recent), encoding: .utf8)!, r.olderCount, r.olderSum, id])
    }

    // MARK: - Sliders — T1-A (CAT-018) ----------------------------------------

    public func setSlider(_ name: String, _ value: Int) async throws {
        let token = try await requirePresence("slider \(name)")
        try append(kind: "SLIDER", subject: name, provenance: .t1, payload: ["value": max(0, min(100, value))], presenceToken: token)
    }
    public func sliders() throws -> [String: Int] {
        var out: [String: Int] = [:]
        for (k, v) in try query("SELECT name,value FROM sliders", []) { (col($0, 0), Int(sqlite3_column_int($0, 1))) } { out[k] = v }
        return out
    }

    // MARK: - SQLite plumbing ------------------------------------------------

    private func exec(_ sql: String) throws {
        var err: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &err) == SQLITE_OK else { let m = String(cString: err!); sqlite3_free(err); throw VaultError.sql(m) }
    }
    private func run(_ sql: String, _ args: [Any]) throws { _ = try query(sql, args) { _ in () } }
    private func query<T>(_ sql: String, _ args: [Any] = [], _ map: (OpaquePointer) -> T) throws -> [T] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw VaultError.sql(String(cString: sqlite3_errmsg(db))) }
        defer { sqlite3_finalize(stmt) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (i, a) in args.enumerated() {
            let idx = Int32(i + 1)
            switch a {
            case let s as String: sqlite3_bind_text(stmt, idx, s, -1, transient)
            case let d as Double: sqlite3_bind_double(stmt, idx, d)
            case let n as Int: sqlite3_bind_int64(stmt, idx, Int64(n))
            case let b as Data: b.withUnsafeBytes { sqlite3_bind_blob(stmt, idx, $0.baseAddress, Int32(b.count), transient) }
            default: sqlite3_bind_null(stmt, idx)
            }
        }
        var rows: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW { rows.append(map(stmt!)) }
        return rows
    }
    private func col(_ s: OpaquePointer, _ i: Int32) -> String { String(cString: sqlite3_column_text(s, i)) }
    private func blob(_ s: OpaquePointer, _ i: Int32) -> Data {
        guard let p = sqlite3_column_blob(s, i) else { return Data() }
        return Data(bytes: p, count: Int(sqlite3_column_bytes(s, i)))
    }
    static func sha256(_ s: String) -> String { SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined() }
}
