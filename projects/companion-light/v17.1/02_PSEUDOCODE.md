# Companion Light Mobile — pseudocode

```
ENUM Trust      { T1 owner, T2 local_model, T3 frontier_model, T4 external }   # PROVENANCE, not truth
ENUM Plane      { CONTEXT (all), EVIDENCE (T1+T4 only) }                        # CAT-007
ENUM Shelf      { RESIDENT, COLD, ORPHAN }
ENUM Role       { LIBRARIAN, JUDGE, VOICE }      # three roles, one set of weights

CONST DECAY = 0.5, RESIDENT_TH = -0.9, COLD_TH = -2.5, MAX_EXACT = 20, DAY = 86400
```

## Vault (append-only, hash-chained, current-state materialized)

```
TABLE events       (seq, id, kind, subject, provenance, ciphertext, prev_hash, hash, owner_sig?)   # IMMUTABLE
TABLE wrapped_keys (event_id, wrap_master(K_obj))          # deleting a row = erasure (CAT-009)
TABLE objects      (id, trust, source, text?, created_at, shelf, embedding?, stub?, tombstone)    # MATERIALIZED
TABLE access       (object_id, recent_json, older_count, older_sum)                              # CAT-013
TABLE receipts (id, question, returned_json, near_json, cutoff, ts)
TABLE sliders  (name, value, ts)     # T1 by construction: only owner UI writes it

append(kind, subject, provenance, payload, presence_token?):
    if kind in T1A_KINDS: REQUIRE presence_token fresh and unspent; spend it        # CAT-018
    K_obj = random_key(); ct = aead_seal(payload, K_obj)
    wrapped_keys.insert(id, aead_seal(K_obj, master_key_from_secure_enclave))
    prev = last(events).hash or "genesis"; seq = next
    h = sha256(prev | seq | kind | subject | provenance | ct)                       # commits to ciphertext + metadata + position
    sig = sign_owner(h) if kind in SIGNED_KINDS                                    # bound to h ⇒ not replayable
    INSERT events; materialize(kind, subject, payload)                             # same transaction

# CAT-010: no function accepts a trust class
ingest_owner(text)            -> create(text, T1, "owner")          # T1-O: signed, no presence
ingest_local(text, role)      -> create(text, T2, "local:"+role)
ingest_frontier(text, model)  -> create(text, T3, "frontier:"+model)
ingest_external(text, origin) -> create(text, T4, "external:"+origin)

promote(t3_id, owner_statement):                # T1-A
    tok = presence_gate.require("promote")
    new = create(owner_statement, T1, "owner_about:"+t3_id)
    append("PROMOTION", new, T1, {about: t3_id}, tok)             # t3 object stays T3

shred(obj_id):                                  # T1-A — CAT-009/016
    tok = presence_gate.require("erase")
    DELETE wrapped_keys WHERE event_id IN events(subject=obj_id)   # text unrecoverable
    append("SHRED", obj_id, T1, {when}, tok)                       # objects row → tombstone; events rows untouched

verify_chain(): recompute h for every event from stored ciphertext+metadata; verify every sig with the vault-held key; fail on first mismatch
```

## Librarian (BM25 + embedding + ACT-R activation; the fold)

```
activation(rec, now):
    total = days(rec.created)^-DECAY                 # creation is a presentation
    for t in rec.recent: total += days(t)^-DECAY
    if rec.older_count: total += older_count * days(older_sum/older_count)^-DECAY    # CAT-013: true mean; never inflates (Jensen)
    return ln(total)
    where days(t) = max((now - t)/DAY, 1.0)

bm25(q_tokens, doc): standard k1=1.5 b=0.75

search(question, plane, k=5, near=3):
    q_vec = embedder.embed(question)
    for each obj where shelf != ORPHAN and not tombstone:
        if plane == EVIDENCE and obj.trust in {T2, T3}: skip           # CAT-007
        lex = bm25(tokens(question), obj)
        sem = cos(q_vec, obj.embedding) if obj.shelf == RESIDENT else 0
        rel = 0.5*lex_norm + 0.5*sem
        if rel <= 0: continue
        score = rel + W_ACT * activation(access[obj], now)
    sort desc; returned = top k; near_misses = next `near`
    touch(returned)                                  # access record updated
    receipt = {question, returned, near, cutoff_reason, searched, orphans_skipped}
    vault.append("RECEIPT", receipt); return receipt

fold(now):                                           # run on charger overnight
    for each obj:
        a = activation(access[obj], now)
        shelf = RESIDENT if a>=RESIDENT_TH else COLD if a>=COLD_TH else ORPHAN
        if shelf == COLD:     drop embedding
        if shelf == ORPHAN:   text -> stub{about, when, who}; remove tokens from df   # CAT-005
        if shelf == RESIDENT and embedding is null: re-embed                        # CAT-012
        vault.append("FOLD", obj, {before, after, a})

rehydrate(obj): text = events.lookup(obj); shelf = RESIDENT; re-embed
```

## Sliders (TARS)

```
SLIDERS = sarcasm, whimsy, precision, warmth, brevity, profanity   (0..100)

fallback_embed(text): bucket = sha256(token) mod dims           # CAT-006: stable across launches

anchor(name, v):                          # proper nouns, not adjectives
    band = v < 25 ? 0 : v < 50 ? 1 : v < 75 ? 2 : 3
    return ANCHORS[name][band]            # e.g. sarcasm: ["none","Bill Nye","Dorothy Parker","Mark Twain at his meanest"]

sampling(sliders):
    temperature = 0.2 + 0.7 * whimsy/100
    top_p       = 0.9 - 0.3 * precision/100
    max_tokens  = brevity>66 ? 256 : brevity>33 ? 512 : 1024

voice_system_prompt(sliders) = persona_block + join(anchor(s) for s in SLIDERS)

set(name, v): vault.sliders.upsert(name, v); vault.append("SLIDER", name, {v}, signed=true)
```

## Persona (the single thing the owner talks to)

```
answer(question):
    nonce     = random()
    receipt   = librarian.search(question, plane=EVIDENCE)
    context   = fence(receipt.returned, nonce, budget=MAX_CHARS)      # CAT-008 metadata on the fence; CAT-015 lowest score dropped first
                # <note-{nonce} trust=T4 source="external:web">...text...</note-{nonce}>

    # --- JUDGE: sliders OFF, temperature 0. Drafts; does NOT route. ---
    raw = local.generate(JUDGE_PROMPT, {question, context}, temp=0)
    verdict = parse(raw) or {local_answer:"", confidence:0, instrument_failed:true}   # CAT-003 fail-closed

    # --- ROUTE: deterministic (CAT-011). Confidence is one input. ---
    triggers = []
    if verdict.instrument_failed:                          triggers += "judge_instrument_failed"
    if receipt.returned empty:                             triggers += "no_retrieval_support"
    if top.relevance < 0.35:                               triggers += "weak_retrieval_support"
    if score[0]-score[1] < 0.05:                           triggers += "ambiguous_retrieval"
    if all returned are T4:                                triggers += "external_only_provenance"
    if question is time-sensitive:                         triggers += "time_sensitive"
    if owner asked for committee:                          triggers += "owner_requested"
    if verdict.confidence < 0.7:                           triggers += "low_local_confidence"
    call_committee = frontier available and triggers non-empty

    spread = null
    if call_committee:
        results = parallel(anthropic, openai, gemini)                # each returns draft OR error
        drafts  = successes -> scratch as T3 (NOT the vault)
        missing = {model: error}                                    # CAT-004 absence is data
        {agree, disagree} = local.generate(SPREAD_PROMPT, drafts, temp=0) if len(drafts) >= 2
        spread = {agree, disagree, expected: len(frontier), returned: len(drafts), missing}

    # --- VOICE: sliders ON. Narrates. Does not render the spread. ---
    reply = local.generate(voice_system_prompt(sliders),
                           {question, context, verdict.local_answer, spread.topics_only}, sampling(sliders))
    ui.render(reply); ui.render_verbatim(spread)                     # CAT-002 the screen holds the pen

    librarian.index(vault.ingest_owner(question))                    # T1-O
    librarian.index(vault.ingest_local(reply, "voice"))              # T2 → context plane only
    return {reply, spread, receipt, verdict, triggers, drafts}

promote_frontier(draft_id, owner_statement):                         # T1-A
    obj = vault.ingest_frontier(draft.text, draft.model); vault.promote(obj, owner_statement)
```

## Runtime boundary (one file per platform; the only thing you swap)

```
INTERFACE ModelRuntime  { load(path); generate(system, user, params) -> text }
INTERFACE Embedder      { embed(text) -> float[] }
INTERFACE Frontier      { complete(provider, key, system, user) -> text }
INTERFACE PresenceGate  { require(reason) -> one_shot_token }        # Face ID / BiometricPrompt   (CAT-018)
INTERFACE KeyStore      { master_key() }                              # Secure Enclave / Keystore   (CAT-009)
```
