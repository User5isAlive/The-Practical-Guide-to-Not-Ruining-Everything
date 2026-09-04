# Cathedral Defect Ledger — Companion Light Mobile

Append-only. IDs are never reused. A later summary cannot close an item; only a diff + a passing test can.
Layer: THEOREM / PSEUDO / CODE / TEST / SECURITY / PERF / PROCESS. Status: OPEN / PATCHED (diff exists, not compiled) / VERIFIED (build+test green) / THEOREM (owner decision) / WONTFIX.

| ID | Layer | File · Symbol | Observed | Invariant | Found by | iOS | Android |
|---|---|---|---|---|---|---|---|
| CAT-001 | TEST | Tests/CoreTests.swift · testChainDetectsTamper | Test never tampers; asserts an untouched chain verifies | A test must fail when the invariant fails | Sol | PATCHED — disk UPDATE via 2nd connection; provenance tamper; sig replay | OPEN |
| CAT-002 | PSEUDO→CODE | Persona.swift · answer() | Spread guard is topic-substring; retry unchecked; Voice can smooth disagreement | Voice narrates the spread, never edits it | Sol | PATCHED — UI renders Spread verbatim; Voice gets topics only | OPEN |
| CAT-003 | CODE | Persona.swift · answer() | Judge parse failure → needsCommittee=false (fail-open) | Instrument failure cannot suppress escalation | Sol | PATCHED — instrumentFailed is a routing trigger | OPEN |
| CAT-004 | CODE | Persona.swift · answer() | `try?` drops failed frontier calls silently | Absence is data | Sol | PATCHED — Spread.expected/returned/missing | OPEN |
| CAT-005 | CODE | Librarian.swift · fold()/indexTokens() | df not decremented on orphan; re-incremented on rehydrate | BM25 statistics must be exact | Sol | PATCHED — removeTokens(); indexTokens idempotent | OPEN |
| CAT-006 | CODE | Persona.swift · HashEmbedder | Swift String.hashValue is per-process seeded; persisted vectors rot on relaunch | Fallback must be deterministic across launches | Sol | PATCHED — SHA-256 bucket | N/A (Kotlin hashCode stable) |
| CAT-007 | THEOREM | Librarian.swift · search() | Voice replies (T2) indexed and retrievable as evidence → recursive echo | Model-written text never grounds an answer (inv. 2/6) | Fable | PATCHED as default: Plane.evidence excludes T2/T3; Plane.context includes. **Owner to ratify.** | OPEN |
| CAT-008 | SECURITY | Persona.swift · answer() | Trust labels inline in prompt text; a T4 note can contain "[T1 owner]" | Text cannot assert its own reliability (inv. 3) | Fable | PATCHED — per-turn nonce fences; trust on the fence | OPEN |
| CAT-009 | SECURITY | Vault.swift · append() | Event payloads cleartext; append-only collides with erasure | Immutable history AND owner-commanded unrecoverability | Sol | PATCHED — per-object AES-GCM key, wrapped by KeyStore master; chain commits ciphertext | OPEN |
| CAT-010 | SECURITY | Vault.swift · ingest() | trust is a caller parameter | Reliability is stamped by construction, not promised | Sol | PATCHED — ingestOwner/Local/Frontier/External; no trust param exists | OPEN |
| CAT-011 | THEOREM | Persona.swift · judgeSystem | Judge grades its own confidence and routes on it | A model may not assess its own competence out of supervision | Sol | PATCHED — Persona.route() deterministic triggers; confidence is one input | OPEN |
| CAT-012 | CODE | Librarian.swift · fold() | COLD→RESIDENT without re-embedding; resident+NULL embedding reachable | resident ⇒ embedded | Sol | PATCHED — fold re-embeds; fold is async | OPEN |
| CAT-013 | CODE | Librarian.swift · activation() | older_span midpoint is an approximation, not the mean; Fable overstated it as "correct" | Quantities must have a defined meaning | Sol (Gemini raised, wrongly fixed) | PATCHED — older_sum sufficient statistic | OPEN |
| CAT-014 | PERF | Librarian.swift · search() | allObjects() loads every embedding per query, O(N) | Search must touch a candidate pool, not the corpus | Fable | OPEN — needs FTS5 + sqlite-vec candidate union → ACT-R rerank | OPEN |
| CAT-015 | CODE | Persona.swift · answer() | No token budget on context | Local runtime is RAM-bound | Gemini | PATCHED — char budget, lowest score dropped first | OPEN |
| CAT-016 | THEOREM/ENGLISH | Vault.swift · shred() | "Tombstone the row" ambiguous between events (immutable) and objects (materialized) | Events row never mutates; objects row may tombstone | Sol | PATCHED — shred touches wrapped_keys + objects only | OPEN |
| CAT-017 | PROCESS | Package.swift · Platform.swift | Core imports Apple-only frameworks; compiler unavailable to reviewers | The compiler must be reachable inside the model loop | Fable | PATCHED — swift-crypto + CSQLite module map, conditional imports | N/A |
| CAT-018 | SECURITY | Vault.swift · append()/promote()/setSlider() | Per-message signature would prove "app signed it", not "owner typed it"; signing raw text is replayable | T1-O = owner input path, hash-bound sig; T1-A = fresh presence for elevation (inv. 5) | Fable + Sol | PATCHED — PresenceGate one-shot tokens; sig over commitment hash | OPEN |
| CAT-019 | SECURITY | (Gemini's proposal) ingestOwner(publicKey:) | Caller-supplied verification key | Vault holds the owner key; never accepts one per call | Fable | CLOSED BY DESIGN — never in canonical code | — |
| CAT-020 | PROCESS | Gemini round 2 & 3 | Reviewer rebuilt from transcript; test targeted an imagined API | Every assertion has an artifact coordinate; builders patch, reviewers review | Fable + Sol | Rule adopted (see 03_PROCESS.md) | — |
| CAT-021 | PROCESS | — | Reviews were sequential and shared context; findings correlated | Blind review: artifact only, no transcript | Fable | OPEN — next review round must be blind | — |
| CAT-022 | TEST | all | 0 successful builds; Sol's Linux attempt stopped at module imports | Reality votes before anyone says "passes" | Sol | OPEN — blocked on CAT-017 verification | OPEN |
| CAT-023 | PROCESS | android/ | Android tree has none of CAT-001…018 applied | One artifact, both platforms, same ledger | Fable | — | OPEN — iOS diff is the spec |
| CAT-024 | THEOREM | 01_FOR_THE_MONKEY.md | Six epistemic statuses proposed (Sol) | Provenance ≠ truth; but a model may not assign status (inv. 4) | Fable | THEOREM — shipped: provenance only + `promoted` flag; owner to decide on a status axis | — |
