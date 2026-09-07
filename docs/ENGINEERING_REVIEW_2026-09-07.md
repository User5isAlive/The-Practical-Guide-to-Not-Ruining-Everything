# Repository engineering review — 2026-09-07

Baseline: `baab3a1b6d9958faf60de11f345f24e779cfb649` (public main).
Scope: repository inventory, supplied v17.1 source restoration, and a separate
local corpus staging/search utility. This was not a blind independent review or
complete security audit. No mobile code was compiled in the local environment.

## Observed and changed

- Main contained documentation and two v17.2 adapters, but no full mobile source,
  package manifest, or test tree. Restored 20 iOS/Android files verbatim from the
  supplied `companion_light_mobile_v17_1(1).zip`. Per-file and archive SHA-256 values
  are in `projects/companion-light/v17.1/RESTORED_SOURCE.json`. Nested Git metadata
  was not imported. The archive's Android sources retain their known older defects.
- The v17.2 manifest references a patch and bundle not present in main. This pass
  does not invent the missing v17.2 core or call the v17.1 restoration v17.2.
- Added a dependency-free Python corpus importer and FTS5 context search with
  source digests, exact text spans, repeat-import deduplication, revision preservation,
  selected ChatGPT branch handling, atomic failure, and retrieval near-misses.
- Added synthetic campaign and adversarial import tests, a Python CI workflow,
  private-workspace ignore rules, import instructions, and pocket/home target design.
- Recorded the integrated/mobile trust-label incompatibility without rewriting
  archival policy or silently promoting imported chat.

## Native blockers remain

The restored Swift source has a default `EphemeralKeyStore` in `Vault.init`; reopening
with a newly generated wrapping key cannot decrypt earlier wrapped event keys.
Production persistence must explicitly provision stable key custody and signing
identity. Current `objects.text` also stores plaintext despite encrypted event
payloads; encrypting the log does not encrypt the entire SQLite file. Shredding must
be evaluated against indexes, journal pages, backups, and other copies as well.

The presence implementation is an interface/test stand-in, not a deployed biometric
consent ceremony. Source restoration is not a finding that these controls work.
The supplied v17.2 adapters remain separate, uncompiled deltas. The old ledger's
PATCHED statuses do not become VERIFIED because their files are now in Git.

## Verification boundary

Run `python3 -m unittest discover -s tests -v` at repository root. The tests exercise
actual SQLite reopen, transactions, FTS retrieval, export branches, revisions,
Unicode spans, and authority constraints. They use fabricated text only. They do
not prove semantic retrieval completeness, secure deletion, model independence,
a live phone build, or safety against an attacker who controls the local database.

The corpus database is plaintext staging, explicitly separate from the encrypted
vault design. Import memory usage is proportional to one export file. Full support
for multimodal and differing provider export versions remains open.

## Local results

On 2026-09-07, all 12 corpus tests passed; all 20 restored source files matched
the recorded SHA-256 and byte count. The documented campaign CLI import/search
completed. A temporary import of one 10,325,378-byte legacy chunk produced 6,303
spans in approximately 1.08 seconds; a lexical query returned five results in
approximately 0.002 seconds. This single local smoke check is not a representative
benchmark or a phone measurement. Its database was temporary and not committed.

## Next concrete engineering gates

1. Recover the exact v17.2 source patch/bundle and reconcile it against the restored
   baseline; do not reconstruct the missing implementation from descriptions.
2. Compile the native core, fix reproduced compiler/test failures, and record logs.
3. Implement durable key custody and meaningful fresh-presence authorization; test
   close/reopen and denied/replayed authorizations before using personal data.
4. Add an explicit reviewed corpus-to-vault staging boundary.
5. Build and measure one authenticated, read-only home-inference path, including
   offline operation and no silent cloud fallback.
