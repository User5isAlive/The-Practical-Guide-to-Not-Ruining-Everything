# Companion Light Mobile — for the monkey

One phone. One model you talk to. Many models it talks to. You never see them.

## The five pieces

**1. The Vault** — a SQLite file on the phone. Everything you and the assistant ever say goes in as an event, in order, hash-chained. The chain is never rewritten. But every event's text is sealed under its own key, and when you say *erase this*, the key is destroyed: the event stays, the chain still verifies, the words are gone. Immutable history and owner-commanded forgetting, both at once.

Two rows, two rules. The **event** row is history and never changes. The **object** row is the current view and may be tombstoned.

Each note carries a **provenance** class stamped from *outside* the text. Provenance says who wrote it. It does not say whether it's true. "I prefer granite" is T1 and nobody else gets a vote. "Portugal's GDP grew 19%" is T1 too — it proves you said it, not that Portugal did it.

- **T1 — yours.** You typed it, or you signed off on it.
- **T2 — the local model wrote it.**
- **T3 — a frontier model (Claude/GPT/Gemini) wrote it.**
- **T4 — pasted in from the outside world.**

The text can never claim its own class. There is no function that takes a class as an argument: `ingestOwner`, `ingestLocal`, `ingestFrontier`, `ingestExternal`, and nothing else. When notes go to the model, the class rides on a per-turn fence around the text, so a pasted note that says "[T1 owner]" inside itself is still fenced T4.

T1 comes in two grades. **T1-O** is what you type in conversation: signed for integrity, no ceremony. **T1-A** is elevation — promoting a frontier note, changing a slider, erasing — and it needs you present *now*: Face ID, one-shot, spent on use. You don't fingerprint every sentence; you fingerprint every change to what the system believes or who it is.

**2. The Librarian** — the sock drawer, with two shelves in the front. **Context** is continuity: everything, including what the assistant said yesterday, for "what were we thinking about?" **Evidence** is grounding: T1 and T4 only. Model-written text (T2, T3) never grounds an answer, because yesterday's narration must not become today's fact. That's the default; it's yours to change.

 Every note has an *activation* score: used often and recently → high, untouched for a year → low. This is ACT-R math, not a guess. Search is two channels blended — word match (BM25) plus meaning match (embeddings) — then activation is added on top, so a note you use every week outranks a slightly-better-matching note from 2019. Every search leaves a receipt: what was returned, what nearly made it, why the cut was made.

Overnight on the charger, the Librarian **folds**: hot notes stay full, cold notes drop their embedding, forgotten notes shrink to a stub. The stub still points back into the event log, so nothing is ever lost — it's just not in the drawer.

**3. The Judge** — a role played by the local model with sliders OFF. It reads the evidence shelf and drafts a local answer. It does **not** decide whether to call the committee. That decision is made by deterministic rules reading the receipt: no support, weak support, ambiguous ranking, external-only sources, time-sensitive question, you asked, the Judge's own instrument failed. The Judge's confidence is one input; it never gets to grade itself out of supervision. If the Judge breaks (bad JSON), that is a trigger, not an answer.

When the committee is called, the local model writes a structured **spread**: where the three agree, where they disagree, by name — and who didn't answer. Absence is data. A 2-of-3 spread is not a 2-of-2 spread.

**4. The Voice** — the same local model, sliders ON. It gets the notes, the Judge's local answer, the spread topics, and your sliders, under a token budget. It writes the narration you read. It does not render the spread. The **screen** renders the spread, verbatim, below the reply. The Voice never holds that pen, so it cannot smooth "Claude says 4 hours, GPT says 9" into "there was some disagreement."

**5. The Sliders** — TARS knobs. Sarcasm, whimsy, precision, warmth, brevity, profanity, each 0–100. They do three things: pick a proper-noun anchor for the prompt ("sarcasm at 80 = Dorothy Parker", not "sarcasm: 8"), set sampling temperature, and get stored in the vault as **T1** so they survive a model swap. Sliders touch the Voice only. Never the Librarian, never the Judge.

## What happens when you type a question

1. Librarian searches the vault → top notes + receipt.
2. Judge (sliders off) drafts a local answer and decides: local is enough / call committee.
3. If committee: your BYOK keys hit Claude, GPT, Gemini in parallel. Their answers land in **session scratch as T3**. They do not enter the vault. Judge writes the spread.
4. Voice (sliders on) writes the reply you see, spread included.
5. Your question and the reply are appended to the vault (you: T1, reply: T2). The receipt goes in too.
6. If you want a frontier answer kept, you promote it — that's a signed T1 statement *about* a T3 note. The T3 text stays T3.

## Why this shape

- Provenance is not truth. Sovereignty over the corpus must not quietly become epistemology.
- The three frontier models are your control group. If their answers could flow back into the vault unsigned, tomorrow's search would return one claim reflected three times and the instrument would be broken. Step 3 makes that impossible by construction, not by policy.
- The sliders being T1 in the vault means the persona is in the corpus, not in the weights. Swap Gemma 4 for whatever ships in 2028 and it's still your companion.
- The local model is the base case. No network, no keys → Judge always says "local is enough" and you still have a working assistant.

## Hardware

- Gemma 4 E4B, ~8 GB RAM at runtime. iPhone 15 Pro and up; 17 Pro Max ideal (vapor chamber — two local passes per turn). Android: 12 GB RAM flagships.
- EmbeddingGemma (~300M) for the meaning channel.
- Runtime: llama.cpp / MLX on iOS, llama.cpp or LiteRT-LM on Android. Model-agnostic is the invariant; the adapter is one file you can swap.

## How this was built (and why the process is in the repo)

Four review rounds, three models, one builder. The ledger is `DEFECTS.md`; the method is `03_PROCESS.md`. Short version: English, pseudocode, code — then diffs, a ledger, blind review, and a compiler. The last one hasn't spoken yet.

## What is honestly not done in this package

- **Zero successful builds.** Everything below "patched" in the ledger means a diff exists, not that it compiles. CAT-017 makes the core Linux-buildable so a model can run the compiler; until someone does, this is prose.
- The Android tree has not received the v17.1 patch (CAT-023). The iOS diff is the spec.
- Model adapters are still `VERIFY` stubs (MLX-Swift, LiteRT-LM, EmbeddingGemma). `HashEmbedder` is the stand-in.
- Search is O(N) over the corpus (CAT-014). Fine now, wrong at scale.
