# Companion Light v17.2 — delta artifacts

v17.2 is the next patch iteration after v17.1. It does **not** change the rule that PATCHED is not VERIFIED.

The supplied v17.2 bundle reports commit:

`2285b431a3d62bfe2edb38a2ce99dc5f51e7f7cc`

with the message:

> v17.2: real MLX + LiteRT-LM adapters written against source (CAT-025/026), Apple-only CompanionRuntimes target (CAT-027), FTS5 candidate pool (CAT-014), Android LiteRT-LM adapter

## What changed

- CAT-014 moves search from all-object scanning toward an **FTS5 (200) ∪ recent (100)** candidate pool. The ledger keeps the known gap explicit: semantic-only hits outside that pool remain invisible until a vector candidate source is added.
- CAT-025 replaces the iOS MLX VERIFY stub with code written against `ml-explore/mlx-swift-lm@e3d4a20`.
- CAT-026 replaces LiteRT-LM VERIFY stubs with code written against `google-ai-edge/LiteRT-LM@b41b3c3` on iOS/Android.
- CAT-027 separates Apple-only runtimes from the Linux-buildable core.
- CAT-028 makes a fresh local generation session per role an explicit theorem-level decision: no Judge KV cache carries into Voice.

## Files preserved here

- [DEFECTS.md](DEFECTS.md) — updated append-only ledger through CAT-028.
- [adapters/MLXRuntime.swift](adapters/MLXRuntime.swift) — supplied iOS MLX adapter.
- [adapters/LocalRuntime.kt](adapters/LocalRuntime.kt) — supplied Android LiteRT-LM adapter.
- [SOURCE_MANIFEST.md](SOURCE_MANIFEST.md) — checksums and source-bundle lineage.

The exact `v17_1_to_v17_2.patch` was supplied out-of-band with this iteration. It is recorded by SHA-256 in the manifest; this GitHub connector cannot ingest the 32 MB nested git bundle cleanly, so the bundle itself is intentionally not committed inside the repository it contains.

## Status

The updated ledger still records **zero successful builds**. Runtime adapters are PATCHED, not VERIFIED. The next meaningful vote is CI/compiler/test output.
