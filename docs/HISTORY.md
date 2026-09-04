# Memory Alpha → Companion Light: working history

This is a reconstruction from the repository history and preserved project chats. It is intentionally a **development history**, not a claim that every intermediate idea was correct.

## Phase 0 — December 2025: the unruly notebook

The newly preserved early material makes the prehistory much clearer.

The original seed was not “build an AGI.” It was a practical continuity problem: how do you use a language model over a long arc without making the model itself the place where persistence lives?

Early v2 material already separates human, model, and external memory, but the labels still move: one v2 document calls the human Student A and the LLM Student B; an intermediate file named “v3” is internally still Version 2.0 and flips the labels; the actual v3 document makes Student A the frontier model, Student B the human, and Student C the collaborative voice/process.

From there the project sprawls aggressively:

- external RAG / NULL-cycle reasoning;
- privacy and GDPR hypotheses;
- proof-of-presence and attestation ideas;
- the model-agnostic companion / “village of models”;
- HOLO-RAG / historical-persona education;
- creator licensing;
- data sovereignty and economic ideas;
- embodied learning and “Everyone Flies”;
- product/application theses around finite generative experiences.

The v4.1/v4.2 “Sovereign State” branch is particularly useful historically because it puts the ambition and the overreach next to each other. It contains speculative legal, biometric, economic, and enforcement claims; it also begins adding explicit known limitations and verification warnings.

The separate Core Architecture document records an important correction event: an external review objected to “zero chance” FOOM language and the project changed the preferred wording to “structurally minimized.” The same artifact also demonstrates why prose review was not enough: absolute language still leaks elsewhere.

That tension eventually becomes the reason for the Cathedral Method.

Reader copies live in [archive/history/early-designs/](../archive/history/early-designs/). Original source bytes and hashes are preserved in the tranche manifests.

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

The repository became the common meeting ground:

- models can review the same commit rather than each other's summaries;
- proposed changes arrive as branches/diffs;
- defects persist in the ledger;
- build/test logs can be attached to the commit or pull request;
- independent reviewers can compare against the same artifact.

That reduces conversational contamination and makes “what actually exists?” answerable by Git rather than memory.

### September 4, 2026 — the models get a pencil

On **2026-09-04**, the human project owner deliberately granted connected frontier models **write access to this GitHub repository**.

That means the repository stops being only a place where a human pastes model output. From this date onward, models can directly create branches, files, commits, and pull requests through the GitHub integration when authorized, and may perform explicitly authorized merges.

This is a provenance milestone, not a transfer of sovereignty. See [ABOUT_THE_MONKEY.md](ABOUT_THE_MONKEY.md).

## Phase 8 — v17.2: real runtime adapters and bounded candidate search

The next Fable patch replaced local-runtime VERIFY stubs with implementation code written against named upstream source revisions and moved search off the full corpus scan:

- **CAT-014:** FTS5 (200) plus recent (100) candidate IDs before fetching full objects;
- **CAT-025:** MLX generation + EmbeddingGemma adapter against `mlx-swift-lm@e3d4a20`;
- **CAT-026:** LiteRT-LM generation + embedding adapters against `LiteRT-LM@b41b3c3`;
- **CAT-027:** Apple-only runtime dependencies isolated from Linux-buildable CompanionCore;
- **CAT-028:** fresh generation session per local role made explicit, preventing Judge KV state from flowing into Voice.

These are still **PATCHED, not VERIFIED**. The ledger continues to record zero successful builds. The exact supplied bundle/patch lineage and checksums are recorded in [projects/companion-light/v17.2/SOURCE_MANIFEST.md](../projects/companion-light/v17.2/SOURCE_MANIFEST.md).

## Preserved source history

Two historical tranches supplied on 2026-09-04 are preserved with hashes rather than silently normalized.

The first includes early public readmes, v7.6, two distinct v8 variants, v9/v10/v12 material, v15/v16 suite checksums, the Mistral/Kimi review bundle, v16g.3 and v16g.4 review/correction artifacts, review-bundler tools, the large “V17” upload, the mobile RAG residency paper, and two research-conversation archives.

The second adds the actual **MA-SUITE-2026.15 ZIP**, early v2/v3/v4.1/v4.2 Word documents, the Core Architecture document, Generalization note, platform thesis, and a historical ChatGPT export showing the ersatz-RAG / cross-model experimentation stage. Exact duplicates of tranche one are identified rather than stored twice.

See:

- [archive/history/README.md](../archive/history/README.md)
- [tranche A manifest](../archive/history/tranches/2026-09-04/MANIFEST.md)
- [tranche B manifest](../archive/history/tranches/2026-09-04-b/MANIFEST.md)
- [MA-SUITE-2026.15](../archive/history/releases/MA-SUITE-2026.15/)

The two supplied HUNTER PDFs in tranche A were byte-identical to the HUNTER object already present in `archive/research/`, so they are recorded in the manifest rather than duplicated.

## Important historical note

Older Memory Alpha material sometimes used categorical language such as “cannot FOOM,” “safe by construction,” “zero risk,” “GDPR compliant by construction,” or numerical model-performance claims that were produced conversationally rather than measured experimentally.

The current project treats those as **historical hypotheses, rhetoric, or provisional claims—not established guarantees**.

The newer process deliberately replaces confident prose with falsifiable invariants, defect IDs, builds, tests, external evidence, explicit unknowns, and an audit trail showing who or what changed the artifact.
