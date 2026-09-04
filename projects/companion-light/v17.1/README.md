# Companion Light Mobile v17.1 — CC0-1.0

Three layers, one design, one ledger:

| File | For whom |
|---|---|
| `01_FOR_THE_MONKEY.md` | plain English — what it does and why |
| `02_PSEUDOCODE.md` | the half-initiated — every algorithm, no language |
| `03_PROCESS.md` | how the committee works, learned the hard way |
| `DEFECTS.md` | the ledger — every finding, its coordinate, its status |
| `ios/` | Swift package (SQLite + CryptoKit + MLX) |
| `android/` | Kotlin (SQLite + Ed25519 + LiteRT-LM or llama.cpp) |

Both ports share the same file map: **Trust → Vault → Librarian → Sliders → Persona → Adapters → UI.**

## Status, honestly

v17.1 is v17.0 plus one diff (`git log` in the repo: two commits). The diff closes CAT-001…013, 015–018 on iOS at the level of **PATCHED**: code and tests exist. Nothing is **VERIFIED**: no build has run. CAT-017 makes `CompanionCore` buildable on Linux (`swift-crypto`, `CSQLite` module map) so that a reviewer with a toolchain can be the first to say so. Android is a recorded gap (CAT-023), not a forgotten one.

Model adapters remain `VERIFY` stubs. `HashEmbedder` stands in.

## The tests (iOS; each names the ledger ID it closes)
Disk tamper via a second SQLite connection · provenance tamper · signature replay · shred keeps chain, loses text · promotion keeps T3 at T3 and needs presence · activation with exact mean · orphan/rehydrate twice with df and embedding intact · stable fallback hash · evidence vs context planes · fence carries trust, not text · routing is deterministic and fail-closed.

To run on Linux: `apt install libsqlite3-dev && swift test`. If it fails at an import, that is CAT-017 reopening, and the log is the deliverable.
