# Memory Alpha v15 — Integrated Protocol Suite

```text
Release ID:       MA-SUITE-2026.15
Release date:     2026-07-22
Status:           Open Research Specification — implementation pending
Specification:    CC0-1.0
Reference tools:  Apache-2.0
Author:           User5sisAlive
```

Memory Alpha is a model-agnostic protocol architecture for persistent,
user-owned AI continuity, governed memory, authority separation, bounded tool
use, model committees, and claim assurance. It is not a hosted service, model,
company, legal product, or canonical implementation.

## The v15 correction

Older drafts allowed each component to carry its own version and refer to other
components by those moving version numbers. That created stale-reference loops.
This release replaces that pattern with one immutable suite snapshot:

```text
ONE RELEASE ID
    MA-SUITE-2026.15

STABLE DOCUMENT IDS
    MA-CORE          constitutional architecture
    MA-PERSONA       portable persona, committees, specialists
    MA-AIRLOCK       trust crossings, action, writeback
    MA-ROUND         model corroboration profile
    MA-CATHEDRAL     claim-assurance protocol
    MA-CELEBRIMBOR   root authority, update, recovery
    MA-FPA           fresh-presence authorization profile
    MA-HUNTER        optional data-rights enforcement profile

ONE PAYLOAD MANIFEST
    RELEASE_MANIFEST.json pins every normative artifact by SHA-256.
```

Documents refer only to stable document IDs. The manifest resolves those IDs to
exact files and hashes. No component independently declares that another
component is “v3,” “v12,” or “latest.” A new suite release changes the manifest
and release ID together.

## Normative priority

```text
MA-CORE: Floor > Containment > Friction
        ↓
MA-CELEBRIMBOR: prevents hidden root sovereignty
        ↓
MA-AIRLOCK: enforces trust, scope, action, and writeback
        ↓
MA-FPA: authenticates fresh user approval for bounded consequences
        ↓
MA-PERSONA / MA-ROUND / MA-CATHEDRAL / MA-HUNTER:
        profiles operating inside those boundaries
```

No lower document may weaken a higher invariant. In conflict, fail closed and
record the conflict.

## Files

- `docs/MEMORY_ALPHA_CORE.md`
- `docs/PORTABLE_PERSONA_COMMITTEE_PROFILE.md`
- `docs/AIRLOCK_SECURITY_PROTOCOL.md`
- `docs/ROUND_TABLE_CORROBORATION_PROFILE.md`
- `docs/CATHEDRAL_ASSURANCE_PROTOCOL.md`
- `docs/CELEBRIMBOR_ROOT_AUTHORITY_PROTOCOL.md`
- `docs/FRESH_PRESENCE_AUTHORIZATION_PROFILE.md`
- `docs/HUNTER_ENFORCEMENT_PROFILE.md`
- `docs/TRUSTED_COMPUTING_BASE.md`
- `docs/MIGRATION_FROM_LEGACY.md`
- `docs/KNOWN_LIMITATIONS.md`
- `docs/REFERENCES.md`
- `pseudocode/END_TO_END_REFERENCE.pseudo`
- schemas, examples, test vectors, and release validator

The exact original suite ZIP is preserved beside this README as
`MEMORY_ALPHA_V15_INTEGRATED_SUITE.zip` with SHA-256
`a3e509f70a285ca8d1a0946deef99498de3abf235b23b613dc4e9c7eac5f08a7`.

## What v15 does not claim

- It does not make hallucination impossible.
- It does not prove semantic completeness.
- It does not make prompt injection impossible.
- It does not automatically satisfy GDPR or any other law.
- It does not prove a remote provider erased or forgot submitted data.
- It does not prove that multiple models are independent or truthful.
- It does not turn pseudocode into an implementation.
- It does not eliminate the need for a declared trusted computing base.

Its central security claim is narrower:

> Language may influence cognition, but language alone must not acquire
> authority, persistence, or consequential power.

## Verification

```bash
python tools/validate_release.py
sha256sum -c MANIFEST.sha256
```

The validator checks manifest hashes, suite headers, stable document references,
JSON examples, selected schemas, pseudocode contracts, and forbidden legacy
claims.

---

Historical release. It does not override the current Companion Light specification,
STATUS document, canonical code, or defect ledger.
