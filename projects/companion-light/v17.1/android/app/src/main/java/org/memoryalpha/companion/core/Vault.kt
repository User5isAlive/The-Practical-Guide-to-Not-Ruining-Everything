// CC0-1.0
// The Vault: append-only, hash-chained event log with materialized state. One SQLite file. Nothing deleted.
package org.memoryalpha.companion.core

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.util.Base64
import java.util.UUID

enum class Trust(val code: String) {
    T1("T1"), T2("T2"), T3("T3"), T4("T4");
    companion object {
        fun of(s: String) = values().first { it.code == s }
        /** Lattice join: least trusted wins. */
        fun join(a: Trust, b: Trust) = if (a.ordinal >= b.ordinal) a else b
    }
}
enum class Shelf { RESIDENT, COLD, ORPHAN }

data class MAObject(val id: String, val trust: Trust, val source: String, val text: String?, val createdAt: Double,
                    val shelf: Shelf, val embedding: FloatArray?, val stub: Map<String, String>?)

data class AccessRecord(val createdAt: Double, val recent: MutableList<Double> = mutableListOf(), var olderCount: Int = 0, var olderSpan: Double = 0.0) {
    fun touch(whenTs: Double, maxExact: Int = 20) {
        recent.add(whenTs)
        if (recent.size > maxExact) { val ev = recent.removeAt(0); olderCount++; olderSpan = maxOf(olderSpan, ev) }
    }
}

data class Event(val seq: Long, val id: String, val kind: String, val subject: String, val payload: String, val prevHash: String, val hash: String, val sig: String?)

class VaultException(msg: String) : Exception(msg)

/** Owner root key. PROD: generate once in AndroidKeyStore; here java.security Ed25519 for portability. */
class OwnerKey(val pair: KeyPair = KeyPairGenerator.getInstance("Ed25519").generateKeyPair()) {
    fun sign(data: ByteArray): String = Signature.getInstance("Ed25519").run { initSign(pair.private); update(data); Base64.getEncoder().encodeToString(sign()) }
    fun verify(data: ByteArray, sig: String): Boolean = Signature.getInstance("Ed25519").run { initVerify(pair.public); update(data); verify(Base64.getDecoder().decode(sig)) }
}

class Vault(ctx: Context, name: String, private val owner: OwnerKey) : SQLiteOpenHelper(ctx, name, null, 1) {
    private val signedKinds = setOf("PROMOTION", "SLIDER", "CAPABILITY")
    private val db: SQLiteDatabase get() = writableDatabase

    override fun onCreate(d: SQLiteDatabase) {
        d.execSQL("CREATE TABLE events(seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT UNIQUE, kind TEXT, subject TEXT, payload TEXT, prev_hash TEXT, hash TEXT, sig TEXT)")
        d.execSQL("CREATE TABLE objects(id TEXT PRIMARY KEY, trust TEXT, source TEXT, text TEXT, created_at REAL, shelf TEXT, embedding BLOB, stub TEXT)")
        d.execSQL("CREATE TABLE access(object_id TEXT PRIMARY KEY, created_at REAL, recent TEXT, older_count INT, older_span REAL)")
        d.execSQL("CREATE TABLE receipts(id TEXT PRIMARY KEY, ts REAL, json TEXT)")
        d.execSQL("CREATE TABLE sliders(name TEXT PRIMARY KEY, value INT, ts REAL)")
    }
    override fun onUpgrade(d: SQLiteDatabase, o: Int, n: Int) {}

    // ---- Event log ---------------------------------------------------------

    fun append(kind: String, subject: String, payload: JSONObject): Event {
        val payloadStr = canonical(payload)
        val prev = lastHash()
        val hash = sha256(prev + kind + subject + payloadStr)
        val sig = if (kind in signedKinds) owner.sign(hash.toByteArray()) else null
        val id = UUID.randomUUID().toString()
        db.beginTransaction()
        try {
            db.insertOrThrow("events", null, ContentValues().apply {
                put("id", id); put("kind", kind); put("subject", subject); put("payload", payloadStr); put("prev_hash", prev); put("hash", hash); put("sig", sig)
            })
            materialize(kind, subject, payload)
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
        val seq = db.rawQuery("SELECT seq FROM events WHERE id=?", arrayOf(id)).use { it.moveToFirst(); it.getLong(0) }
        return Event(seq, id, kind, subject, payloadStr, prev, hash, sig)
    }

    private fun materialize(kind: String, subject: String, p: JSONObject) {
        val now = System.currentTimeMillis() / 1000.0
        when (kind) {
            "OBJECT_CREATED" -> {
                db.insertOrThrow("objects", null, ContentValues().apply {
                    put("id", subject); put("trust", p.getString("trust")); put("source", p.getString("source")); put("text", p.getString("text")); put("created_at", p.getDouble("created_at")); put("shelf", "RESIDENT") })
                db.insertOrThrow("access", null, ContentValues().apply { put("object_id", subject); put("created_at", p.getDouble("created_at")); put("recent", "[]"); put("older_count", 0); put("older_span", 0.0) })
            }
            "FOLD" -> when (p.getString("after")) {
                "COLD" -> db.execSQL("UPDATE objects SET shelf='COLD', embedding=NULL WHERE id=?", arrayOf(subject))
                "ORPHAN" -> db.execSQL("UPDATE objects SET shelf='ORPHAN', embedding=NULL, text=NULL, stub=? WHERE id=?", arrayOf(p.getString("stub"), subject))
                else -> db.execSQL("UPDATE objects SET shelf='RESIDENT' WHERE id=?", arrayOf(subject))
            }
            "REHYDRATE" -> db.execSQL("UPDATE objects SET shelf='RESIDENT', text=?, stub=NULL WHERE id=?", arrayOf(p.getString("text"), subject))
            "SLIDER" -> db.execSQL("INSERT INTO sliders(name,value,ts) VALUES(?,?,?) ON CONFLICT(name) DO UPDATE SET value=excluded.value, ts=excluded.ts", arrayOf(subject, p.getInt("value"), now))
            "RECEIPT" -> db.execSQL("INSERT INTO receipts(id,ts,json) VALUES(?,?,?)", arrayOf(subject, now, p.getString("json")))
            else -> {}
        }
    }

    fun verifyChain(): Boolean {
        var prev = "genesis"
        for (e in events()) {
            if (e.prevHash != prev) throw VaultException("chain broken at ${e.seq}")
            if (sha256(prev + e.kind + e.subject + e.payload) != e.hash) throw VaultException("hash mismatch at ${e.seq}")
            if (e.sig != null && !owner.verify(e.hash.toByteArray(), e.sig)) throw VaultException("bad signature at ${e.seq}")
            prev = e.hash
        }
        return true
    }

    fun events(): List<Event> = db.rawQuery("SELECT seq,id,kind,subject,payload,prev_hash,hash,sig FROM events ORDER BY seq", null).use { c ->
        generateSequence { if (c.moveToNext()) Event(c.getLong(0), c.getString(1), c.getString(2), c.getString(3), c.getString(4), c.getString(5), c.getString(6), if (c.isNull(7)) null else c.getString(7)) else null }.toList()
    }

    private fun lastHash(): String = db.rawQuery("SELECT hash FROM events ORDER BY seq DESC LIMIT 1", null).use { if (it.moveToFirst()) it.getString(0) else "genesis" }

    // ---- Objects -----------------------------------------------------------

    /** Trust is supplied by the caller. Never parsed from text. */
    fun ingest(text: String, trust: Trust, source: String, now: Double = System.currentTimeMillis() / 1000.0): MAObject {
        val id = UUID.randomUUID().toString()
        append("OBJECT_CREATED", id, JSONObject().put("trust", trust.code).put("source", source).put("text", text).put("created_at", now))
        return MAObject(id, trust, source, text, now, Shelf.RESIDENT, null, null)
    }

    /** Owner makes a signed T1 statement ABOUT a T3/T4 object; the object keeps its class. */
    fun promote(aboutId: String, ownerStatement: String): MAObject {
        val target = obj(aboutId)
        if (target.trust == Trust.T1) throw VaultException("already T1")
        val stmt = ingest(ownerStatement, Trust.T1, "owner_about:$aboutId")
        append("PROMOTION", stmt.id, JSONObject().put("about", aboutId).put("about_trust", target.trust.code))
        return stmt
    }

    fun obj(id: String): MAObject = objects("id=?", arrayOf(id)).firstOrNull() ?: throw VaultException("not found $id")
    fun allObjects(): List<MAObject> = objects("1=1", emptyArray())

    private fun objects(where: String, args: Array<String>): List<MAObject> =
        db.rawQuery("SELECT id,trust,source,text,created_at,shelf,embedding,stub FROM objects WHERE $where", args).use { c ->
            generateSequence {
                if (!c.moveToNext()) null else {
                    val emb = if (c.isNull(6)) null else c.getBlob(6).let { b -> java.nio.ByteBuffer.wrap(b).asFloatBuffer().let { fb -> FloatArray(fb.remaining()).also { fb.get(it) } } }
                    val stub = if (c.isNull(7)) null else JSONObject(c.getString(7)).let { j -> j.keys().asSequence().associateWith { j.getString(it) } }
                    MAObject(c.getString(0), Trust.of(c.getString(1)), c.getString(2), if (c.isNull(3)) null else c.getString(3), c.getDouble(4), Shelf.valueOf(c.getString(5)), emb, stub)
                }
            }.toList()
        }

    fun setEmbedding(id: String, v: FloatArray) {
        val buf = java.nio.ByteBuffer.allocate(v.size * 4); buf.asFloatBuffer().put(v)
        db.execSQL("UPDATE objects SET embedding=? WHERE id=?", arrayOf(buf.array(), id))
    }

    fun textFromLog(id: String): String? = events().firstOrNull { it.kind == "OBJECT_CREATED" && it.subject == id }?.let { JSONObject(it.payload).getString("text") }

    // ---- Access ------------------------------------------------------------

    fun access(id: String): AccessRecord = db.rawQuery("SELECT created_at,recent,older_count,older_span FROM access WHERE object_id=?", arrayOf(id)).use { c ->
        if (!c.moveToFirst()) throw VaultException("no access $id")
        val arr = JSONArray(c.getString(1)); AccessRecord(c.getDouble(0), (0 until arr.length()).map { arr.getDouble(it) }.toMutableList(), c.getInt(2), c.getDouble(3))
    }
    fun saveAccess(id: String, r: AccessRecord) = db.execSQL("UPDATE access SET recent=?, older_count=?, older_span=? WHERE object_id=?", arrayOf(JSONArray(r.recent).toString(), r.olderCount, r.olderSpan, id))

    // ---- Sliders: T1 by construction ---------------------------------------

    fun setSlider(name: String, value: Int) { append("SLIDER", name, JSONObject().put("value", value.coerceIn(0, 100))) }
    fun sliders(): Map<String, Int> = db.rawQuery("SELECT name,value FROM sliders", null).use { c -> generateSequence { if (c.moveToNext()) c.getString(0) to c.getInt(1) else null }.toMap() }

    // ---- helpers -----------------------------------------------------------
    private fun canonical(j: JSONObject): String = JSONObject(j.keys().asSequence().sorted().associateWith { j.get(it) }).toString()
    companion object {
        fun sha256(s: String): String = MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).joinToString("") { "%02x".format(it) }
    }
}
