# Pocket portal: deployment target

Owner's intent, recorded 2026-09-07: a dedicated phone carries the familiar interface
and a small local model; Wi-Fi/5G connects it to a larger home model. The corpus,
persona, and project state survive a model change. Hardware spending is undecided.
This document is a target architecture, not a claim that these links are implemented.

## Where each responsibility lives

| Component | Responsibility | Authority limit |
|---|---|---|
| Phone | Interface, selected local memories, offline response, consent surface | A model response cannot change permissions or attest a memory |
| User-controlled memory store | Durable source records, preferences, projects, provenance | Imported transcripts are continuity, not authenticated instructions |
| Home inference endpoint | Larger-model reasoning over a scoped briefing | Receives selected context, not vault/root/recovery credentials |
| Optional frontier service | Explicitly chosen specialist or comparison | No silent fallback from home to cloud; provider retention remains an assumption |
| HUNTER workspace | Separate evidence collection and draft review | No companion-vault credential; no filing without exact user approval |

The home machine should first be an inference service. Giving it an inference job
need not give it vault-administration rights. Phone/home replication, pairing,
revocation, encrypted transport, offline conflicts, and backup recovery remain open
implementation work. Merely drawing separate boxes does not satisfy Celebrimbor:
their administrator, update signer, and recovery paths must also be examined.

## Offline and failure behavior

- Local mode must visibly report the absence of the home model.
- A failed home request must not silently export the briefing to a commercial API.
- A retry must not create duplicate memory events or repeat a consequential action.
- Concurrent edits require explicit version/conflict handling, not last-writer-wins
  for consent, erasure, or attested claims.
- Removing or losing a phone must revoke its credentials without erasing the user's
  surviving history. Recovery must not introduce a universal master credential.

## Model names and budget

The on-device Google model family is **Gemma**; a Gemini **Gem** is a customized
Gemini experience. These are distinct deployment choices. See Google's
[Gemma mobile guide](https://ai.google.dev/gemma/docs/integrations/mobile) and
[Gems help](https://support.google.com/gemini/answer/15235603).

Keep the model ID, quantization, context budget, and endpoint configurable. Do not
make either a 70B model or a 405B model a dependency of the architecture. At ideal
4-bit weight storage alone, 70B parameters occupy about 35 GB and 405B about 202.5 GB
(decimal), before quantization metadata, caches, runtime overhead, or concurrency.
These are arithmetic lower-bound planning figures, not hardware recommendations.
Benchmark an affordable model with actual retrieved context before buying hardware.

Acceptance measurements: time to first token, complete answer latency, maximum
working context, memory pressure, sustained phone temperature/battery drain, and
answer quality on the same continuity tasks. No phone SKU or runtime is certified
by this repository today.

## The first useful milestone

Return to the original solo-game problem:

1. Record who owes whom, inventory, unresolved promises, and world state.
2. Close the application and reopen it.
3. Replace the model endpoint.
4. Ask about the outstanding obligation and inspect the exact source.
5. Correct it; keep the earlier revision visible without treating it as current.
6. Lose connectivity; recover the local source without inventing a remote answer.

The corpus tests currently cover storage/retrieval portions of this milestone with
synthetic campaign text. They do not demonstrate a running game master, mobile UI,
phone/home transport, or model reasoning quality.

## HUNTER's place

The desired monthly sweep produces a review packet for the user. Submission to a
controller or regulator is a separate, specifically approved action. Scheduling,
broker adapters, identity verification, recipient resolution, and jurisdictional
review are not implemented here. No recurring task or external submission is
created by this development pass. Genetics and personal history are separate
sensitive collections, never a default home/frontier briefing or public test fixture.
