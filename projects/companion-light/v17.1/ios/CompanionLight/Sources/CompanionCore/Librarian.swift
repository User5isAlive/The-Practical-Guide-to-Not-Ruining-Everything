// CC0-1.0
// The Librarian: retrieval (BM25 + embedding), ACT-R activation, and the fold.
// Ported from companion_light/librarian.py v16g.5. Same numbers, same thresholds.
import Foundation

public enum Tunables {
    public static let decay = 0.5                 // ACT-R d
    public static let secondsPerDay = 86400.0
    public static let residentThreshold = -0.9    // ~used within the last week
    public static let coldThreshold = -2.5        // ~one use, 1–2 years ago
    public static let maxExactAccesses = 20
    public static let activationWeight = 0.35     // how much the drawer position moves the rank
    public static let bm25k1 = 1.5, bm25b = 0.75
}

public struct Candidate: Codable { public let objectId: String; public let relevance: Double; public let activation: Double; public let score: Double; public let shelf: String; public let trust: String }

/// CAT-007. Memory has two planes. CONTEXT is continuity (everything). EVIDENCE is grounding: T1 and T4 only;
/// T2/T3 are model-written and never ground an answer. Owner-level decision; this is the shipped default.
public enum Plane: String, Codable { case context, evidence }

public struct SelectionReceipt: Codable {
    public let plane: Plane
    public let question: String
    public let returned: [Candidate]
    public let nearMisses: [Candidate]
    public let cutoffReason: String
    public let searched: Int
    public let orphansSkipped: Int
    public var json: String { String(data: try! JSONEncoder().encode(self), encoding: .utf8)! }
}

public func tokenize(_ s: String) -> [String] {
    s.lowercased().split { !($0.isLetter || $0.isNumber || $0 == "'") }.map(String.init)
}

/// ACT-R base-level activation: A = ln( Σ t_j^-d ). Creation counts as a presentation.
public func activation(_ r: AccessRecord, now: Double, decay: Double = Tunables.decay) -> Double {
    func days(_ t: Double) -> Double { max((now - t) / Tunables.secondsPerDay, 1.0) }
    var total = pow(days(r.createdAt), -decay)
    for t in r.recent { total += pow(days(t), -decay) }
    if r.olderCount > 0 {
        // CAT-013: true mean of the evicted timestamps. Convexity of t^-d means this never inflates activation.
        let meanAge = max((now - r.olderSum / Double(r.olderCount)) / Tunables.secondsPerDay, 1.0)
        total += Double(r.olderCount) * pow(meanAge, -decay)
    }
    return total <= 0 ? -Double.infinity : log(total)
}

public func shelfFor(_ a: Double) -> Shelf {
    a >= Tunables.residentThreshold ? .resident : (a >= Tunables.coldThreshold ? .cold : .orphan)
}

public final class Librarian {
    private let vault: Vault
    private let embedder: Embedder
    private var docs: [String: [String]] = [:]     // object_id -> tokens
    private var df: [String: Int] = [:]

    public init(vault: Vault, embedder: Embedder) throws {
        self.vault = vault; self.embedder = embedder
        for o in try vault.allObjects() where o.text != nil { indexTokens(o.id, o.text!) }
    }

    private func indexTokens(_ id: String, _ text: String) {
        removeTokens(id)                                   // CAT-005: idempotent; rehydrate must not double-count
        let toks = tokenize(text)
        docs[id] = toks
        for t in Set(toks) { df[t, default: 0] += 1 }
    }
    private func removeTokens(_ id: String) {
        guard let old = docs.removeValue(forKey: id) else { return }
        for t in Set(old) { df[t] = max((df[t] ?? 1) - 1, 0); if df[t] == 0 { df[t] = nil } }
    }

    /// Index a freshly ingested object: tokens now, embedding now (RESIDENT ⇒ embedded).
    public func index(_ obj: MAObject) async throws {
        guard let text = obj.text else { return }
        indexTokens(obj.id, text)
        let v = try await embedder.embed(text)
        try vault.setEmbedding(obj.id, v)
    }

    private func bm25(_ q: [String], _ id: String) -> Double {
        guard let doc = docs[id], !doc.isEmpty else { return 0 }
        let n = Double(docs.count)
        let avg = max(Double(docs.values.reduce(0) { $0 + $1.count }) / max(n, 1), 1)
        var counts: [String: Int] = [:]
        for t in doc { counts[t, default: 0] += 1 }
        var s = 0.0
        for term in q {
            guard let tf = counts[term], tf > 0 else { continue }
            let d = Double(max(df[term] ?? 0, 1))
            let idf = log(1 + (n - d + 0.5) / (d + 0.5))
            let denom = Double(tf) + Tunables.bm25k1 * (1 - Tunables.bm25b + Tunables.bm25b * Double(doc.count) / avg)
            s += idf * (Double(tf) * (Tunables.bm25k1 + 1)) / denom
        }
        return s
    }

    private func cosine(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, na: Float = 0, nb: Float = 0
        for i in 0..<a.count { dot += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i] }
        return na == 0 || nb == 0 ? 0 : Double(dot / (sqrt(na) * sqrt(nb)))
    }

    /// Two channels blended, activation added, receipt written. Touching is the side effect that makes the drawer learn.
    public func search(_ question: String, plane: Plane = .evidence, limit: Int = 5, nearMissWindow: Int = 3, now: Double = Date().timeIntervalSince1970, touch: Bool = true) async throws -> SelectionReceipt {
        let q = tokenize(question)
        let qv = try await embedder.embed(question)
        let objects = try vault.allObjects()
        var scored: [Candidate] = []
        var orphans = 0
        var lexRaw: [(MAObject, Double, Double)] = []
        for o in objects {
            if o.shelf == .orphan { orphans += 1; continue }
            if plane == .evidence && (o.trust == .t2 || o.trust == .t3) { continue }   // CAT-007
            let lex = bm25(q, o.id)
            let sem = (o.shelf == .resident && o.embedding != nil) ? cosine(qv, o.embedding!) : 0
            if lex <= 0 && sem <= 0 { continue }
            lexRaw.append((o, lex, sem))
        }
        let lexMax = max(lexRaw.map { $0.1 }.max() ?? 1, 1e-9)
        for (o, lex, sem) in lexRaw {
            let rel = 0.5 * (lex / lexMax) + 0.5 * max(sem, 0)
            let act = activation(try vault.access(o.id), now: now)
            scored.append(Candidate(objectId: o.id, relevance: rel, activation: act,
                                    score: rel + Tunables.activationWeight * act, shelf: o.shelf.rawValue, trust: o.trust.rawValue))
        }
        scored.sort { $0.score > $1.score }
        let returned = Array(scored.prefix(limit))
        let near = Array(scored.dropFirst(limit).prefix(nearMissWindow))
        if touch { for c in returned { var r = try vault.access(c.objectId); r.touch(now); try vault.saveAccess(c.objectId, r) } }
        let receipt = SelectionReceipt(plane: plane, question: question, returned: returned, nearMisses: near,
                                       cutoffReason: scored.count > limit ? "count limit" : "no further matches",
                                       searched: objects.count - orphans, orphansSkipped: orphans)
        try vault.append(kind: "RECEIPT", subject: UUID().uuidString, provenance: nil, payload: ["json": receipt.json])
        return receipt
    }

    /// The fold. Run on charger, overnight. Rewrites the view; the log keeps every byte.
    public func fold(now: Double = Date().timeIntervalSince1970) async throws -> [(String, Shelf, Shelf)] {
        var moves: [(String, Shelf, Shelf)] = []
        for o in try vault.allObjects() {
            let a = activation(try vault.access(o.id), now: now)
            let after = shelfFor(a)
            guard after != o.shelf else { continue }
            var payload: [String: Any] = ["before": o.shelf.rawValue, "after": after.rawValue, "activation": a]
            if after == .orphan {
                let stub = ["about": String(tokenize(o.text ?? "").prefix(8).joined(separator: " ")),
                            "when": String(o.createdAt), "who": o.source, "trust": o.trust.rawValue]
                payload["stub"] = String(data: try JSONEncoder().encode(stub), encoding: .utf8)!
                removeTokens(o.id)                        // CAT-005
            }
            try vault.append(kind: "FOLD", subject: o.id, provenance: nil, payload: payload)
            if after == .resident, o.embedding == nil, let t = o.text {   // CAT-012: resident ⇒ embedded
                try vault.setEmbedding(o.id, try await embedder.embed(t))
            }
            moves.append((o.id, o.shelf, after))
        }
        return moves
    }

    public func rehydrate(_ id: String) async throws {
        guard let text = try vault.textFromLog(id) else { throw VaultError.notFound(id) }
        try vault.append(kind: "REHYDRATE", subject: id, provenance: nil, payload: ["text": text])
        try await index(try vault.object(id))
    }
}
