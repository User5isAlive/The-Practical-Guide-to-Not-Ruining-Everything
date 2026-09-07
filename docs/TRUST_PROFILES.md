# Trust labels require a profile

The integrated suite and mobile prototype reuse labels with different meanings.
They are not wire-compatible. A stored `T3` without a profile is ambiguous.

| Label | MA-SUITE-2026.16 | Companion Light mobile v17.1 |
|---|---|---|
| T0 | Constitutional policy enforced externally | No corresponding enum case |
| T1 | Exact human-attested claim | Owner-origin text or owner statement; T1-O/T1-A discussed in prose |
| T2 | Derived/model material | Local-model material |
| T3 | External material | Frontier-model material |
| T4 | Quarantine | External material |

Source: the supplied integrated review bundle's MA-CORE and restored mobile
`Trust.swift`/`01_FOR_THE_MONKEY.md`. This records the incompatibility; it does not
retroactively change either historical specification.

Migration must preserve original profile, source object, provenance, and attestation
evidence. Never translate by numeric rank alone. In particular, mobile owner-origin
text does not establish the exact attestation required by suite T1. A pasted quotation
can be in an owner-origin message without being a claim the owner endorses.

The new corpus staging format uses explicit `provider`, `role`, source hashes and
`authority=NONE`, not T labels. Provider and role are export claims. There is no
automatic promotion or mobile-vault writeback. This keeps the next corpus import
from silently selecting one of the incompatible trust interpretations.
