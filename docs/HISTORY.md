# Memory Alpha → Companion Light: working history

This is a reconstruction from the repository history and preserved project chats. It is intentionally a **development history**, not a claim that every intermediate idea was correct.

## Phase 1 — External memory, stateless models

The earliest stable idea was that continuity should live **outside** model weights: a user-controlled RAG/memory layer provides selected state on wake while the model itself remains replaceable and comparatively stateless.

The old Memory Alpha materials emphasized:

- user-owned long-term memory;
- minimal context/state injection;
- deletion and curation under user control;
- model-agnostic routing;
- a human as the persistent intentional agent.

The repository created in December 2025 and the later V9 README captured this phase. That README is preserved at [archive/README-Memory-Alpha-v9.md](../archive/README-Memory-Alpha-v9.md).

## Phase 2 — Sovereignty, orchestration, and the companion layer

The architecture sharpened from “a chatbot with memory” into a stronger inversion:

- identity and continuity belong to the user-side system;
- frontier models are replaceable cognitive services;
- a local companion can be the persistent intermediary;
- persona controls are explicit user-owned state rather than fine-tuned personality weights.

This is where the idea of one persistent companion speaking to multiple frontier systems became central.

## Phase 3 — Three-language engineering

A recurring problem was that natural-language architecture could sound coherent while implementation details drifted. The project adopted a three-layer rule:

1. **English** — what the system means and why;
2. **Pseudocode** — every noun becomes state, an operation, or an invariant;
3. **Code** — runtime and APIs force the mechanism to exist.

The rule became recursive: if code exposes a theorem error, the repair climbs back upward rather than merely patching code.

## Phase 4 — Companion Light v17.0

On 2026-09-04, a Fable 5.1 build pass produced a mobile vertical slice for iOS and Android, including:

- hash-chained SQLite vault;
- provenance classes T1–T4;
- BM25 + embedding retrieval with ACT-R-style activation;
- fold/orphan/rehydration behavior;
- TARS persona sliders;
- local Librarian/Judge/Voice roles;
- frontier calls to Claude/GPT/Gemini;
- structured disagreement (“Spread”);
- minimal mobile UI.

The initial package was useful precisely because it was imperfect enough to test the method.

## Phase 5 — Multi-model red team

The artifact was reviewed across several model lineages, including GPT-5.6 Sol, Fable 5.1, and Gemini 3.1 Extended. Review exposed bugs and theorem-level gaps including:

- a tamper test that did not actually tamper;
- Voice being able to smooth structured disagreement;
- Judge parse failure suppressing escalation;
- failed committee members disappearing silently;
- BM25 document-frequency drift;
- an unstable Swift fallback hash across process launches;
- trust/provenance being caller-supplied;
- model-written T2 continuity recursively becoming evidence;
- spoofable trust labels inside prompt text;
- self-confidence being used to decide whether the model needed outside review;
- append-only history conflicting with meaningful erasure;
- conversational laundering: reviewers reconstructing code from summaries instead of patching the canonical artifact.

The committee also caught one another's mistakes. That became part of the method rather than an embarrassment to hide.

## Phase 6 — The Cathedral Method and v17.1

The process itself became an artifact.

v17.1 added or formalized:

- a persistent defect ledger;
- PATCHED vs VERIFIED status;
- one canonical artifact;
- artifact coordinates for every defect;
- builders patch, reviewers review;
- blind review before comparing reviewer outputs;
- compiler/test output as a separate authority;
- Context vs Evidence retrieval planes;
- provenance explicitly separated from truth;
- deterministic escalation triggers rather than self-confidence alone;
- UI-owned rendering of disagreement;
- cryptographic-shredding direction for owner-commanded erasure;
- one-shot fresh-presence authorization for elevation actions.

See [projects/companion-light/v17.1/03_PROCESS.md](../projects/companion-light/v17.1/03_PROCESS.md) and [DEFECTS.md](../projects/companion-light/v17.1/DEFECTS.md).

## Phase 7 — GitHub as the committee sandbox

The next process step is to make the repository itself the common meeting ground:

- models review the same commit rather than each other's summaries;
- proposed changes arrive as branches/diffs;
- defects persist in the ledger;
- build/test logs can be attached to the commit or pull request;
- independent reviewers can compare against the same artifact.

That reduces conversational contamination and makes “what actually exists?” answerable by Git rather than memory.

## Important historical note

Older Memory Alpha material sometimes used categorical language such as “cannot FOOM,” “safe by construction,” or “GDPR compliant by construction.” The current project treats those as **historical hypotheses or aspirations, not established guarantees**. The newer process deliberately replaces confident prose with falsifiable invariants, defect IDs, tests, and explicit unknowns.
