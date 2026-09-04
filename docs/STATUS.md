# Current status

## Companion Light v17.2

**Research prototype — not production software.**

v17.2 advances the implementation delta but does not change the verification rule.

Current ledger state includes:

- iOS fixes for many CAT-001…018 items remain **PATCHED**;
- CAT-014 now has an FTS5 + recency candidate-pool patch rather than an O(N) full-object search, with the semantic-only-hit gap still recorded;
- CAT-025/026 replace the MLX and LiteRT-LM VERIFY stubs with adapters written against named upstream source commits;
- CAT-027 isolates Apple-only runtime dependencies from the Linux-buildable core;
- CAT-028 makes fresh local sessions per role an explicit design decision;
- Android now has the LiteRT-LM adapter patch, but the broad Android CAT-001…018 repair set is still not complete;
- **zero successful builds are still recorded**.

The authoritative current ledger is:
[projects/companion-light/v17.2/DEFECTS.md](../projects/companion-light/v17.2/DEFECTS.md).

The source lineage/checksums for the supplied v17.2 patch, adapters, ledger, and git bundle are recorded in:
[projects/companion-light/v17.2/SOURCE_MANIFEST.md](../projects/companion-light/v17.2/SOURCE_MANIFEST.md).

## Claim discipline

This repository does **not** currently claim that Memory Alpha or Companion Light:

- solves AI alignment;
- guarantees prevention of recursive self-improvement or “FOOM”;
- is GDPR-compliant as a matter of law;
- has passed a security audit;
- has a verified mobile build;
- makes multiple frontier models statistically independent.

Those are exactly the kinds of claims the Cathedral Method is designed to turn into narrower, testable statements.

## What is reasonably demonstrated so far

At the architectural/specification level, the project has a coherent design for:

- separating persistent user memory/persona from replaceable frontier models;
- tracking provenance without equating provenance with truth;
- separating model-written continuity from evidence grounding;
- preserving disagreement instead of collapsing it into consensus;
- carrying defects forward across review rounds;
- using a canonical artifact, diffs, compiler results, and tests to reduce conversational/specification laundering.

At the implementation level, runtime adapters and candidate-pool search are now concrete patches, but they remain subject to compilation, runtime testing, upstream-API verification, and further red-team review.

## Reading rule

**PATCHED means code exists. VERIFIED means reality voted.**

If a README sentence and the defect ledger disagree, the ledger wins.
