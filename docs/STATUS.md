# Current status

## Companion Light v17.1

**Research prototype — not production software.**

The current v17.1 documents report:

- iOS fixes for many CAT-001…018 items are **PATCHED**, meaning a diff exists;
- **zero successful builds are yet recorded**;
- Android has not received the v17.1 repair set;
- local MLX/LiteRT-LM/EmbeddingGemma adapters remain VERIFY stubs;
- search is still O(N) and is known not to be the final scaling design.

The authoritative status is the defect ledger:
[projects/companion-light/v17.1/DEFECTS.md](../projects/companion-light/v17.1/DEFECTS.md).

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

At the implementation level, those remain subject to build/test verification and further red-team review.

## Reading rule

**PATCHED means code exists. VERIFIED means reality voted.**

If a README sentence and the defect ledger disagree, the ledger wins.
