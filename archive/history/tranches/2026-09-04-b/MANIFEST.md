# 2026-09-04 historical tranche B manifest

This is the second historical tranche supplied on 2026-09-04.

The archive follows two rules:

1. **Preserve provenance.** Hashes and original labels are recorded even when filenames or internal versions disagree.
2. **Make it readable.** Older DOCX material is indexed in `../../early-designs/`; original source bytes remain in the source bundle.

## Unique-source bundle

Files not already preserved byte-for-byte in the first 2026-09-04 tranche are stored in:

`memory-alpha-history-tranche-unique.tar.gz`

SHA-256:

`69328f980186bdbd9108d211f77c3a655dca68a5fefabf2d2bbf0214b0136fef`

The bundle contains **11 unique supplied files**. Exact duplicates of the first tranche are not needlessly stored again.

## Inventory

| Supplied filename | Bytes | SHA-256 | Archive status | Note |
|---|---:|---|---|---|
| `MEMORY_ALPHA_V15_INTEGRATED_SUITE(1).zip` | 78,423 | `a3e509f70a285ca8d1a0946deef99498de3abf235b23b613dc4e9c7eac5f08a7` | new in this tranche | Actual V15 integrated suite. Its SHA-256 matches the hash pinned by the previously archived V15 `.sha256` file. |
| `MEMORY_ALPHA_V8_README(1).md` | 15,174 | `b081f365da9dae163f99a76631ff53d2b2ef31db1b4fa5537dd1215664e7ecb0` | duplicate already preserved | same bytes as `MEMORY_ALPHA_V8_README.md` in first 2026-09-04 tranche |
| `memory_alpha_README_v8(1).md` | 13,881 | `c73d8d338ce23d3dda645cd3bb2ccc13d7b254e346e621989242f6c1624aa428` | duplicate already preserved | same bytes as `memory_alpha_README_v8.md` in first 2026-09-04 tranche |
| `Memory_Alpha_README (1)(1).md` | 4,851 | `4db7ad156ba8690955463bd02b50cfa6b4ad2ec3f7311854a3c7d70ae0eb00c0` | duplicate already preserved | same bytes as `Memory_Alpha_README (1).md` in first 2026-09-04 tranche |
| `memory_alpha_lite_v7.6(2).md` | 25,120 | `1c8fac308ac08d8ed4bba475be2f75f9ee7d3ccb52f732f90a503a6b842a43b6` | duplicate already preserved | same bytes as `memory_alpha_lite_v7.6(1).md` in first 2026-09-04 tranche |
| `memory_alpha_lite_mobile_rag_residency_paper_draft(1).md` | 3,408 | `df21a00a378cc352c00c10165f3799379ef1f7e852330aead0748f422925f478` | duplicate already preserved | same bytes as prior tranche copy |
| `memory_alpha_platform_thesis.md` | 13,353 | `3c3d2f067a8c2cbcb1520b1a4a991d3c20e32e43e3dd5f93b0cf1a9d43da5606` | new in this tranche | Historical platform/product thesis. Numeric usage and market claims preserved as claims, not treated as current evidence. |
| `ChatGPT-Memory Alpha explanation.json` | 34,296 | `193a96b6c09484b3d49f3ee572ed7a0da3ad8bbde23e6aea85489ef74707821b` | new in this tranche | Historical ChatGPT export showing ersatz-RAG explanation, cross-model experiment framing, and model-generated quantitative uplift estimates. Those estimates are not current measured results. |
| `Memory_Alpha_GENERALIZATION.md` | 3,245 | `303ff99ab81db673580416dd52f6b6f7fdec0425422603b37659f32837725ed7` | new in this tranche | Historical human-led generalization thesis. Preserved, not endorsed as established AGI/safety proof. |
| `Memory_Alpha_README.md` | 4,851 | `4db7ad156ba8690955463bd02b50cfa6b4ad2ec3f7311854a3c7d70ae0eb00c0` | duplicate already preserved | byte-identical to `Memory_Alpha_README (1)(1).md` and the prior tranche copy |
| `Memory_Alpha_Core_Architecture.docx` | 14,242 | `8fe1d52704efb57f044fc9e41d1b730756b29c588bce04b1725768d2dbf264d9` | new in this tranche | Core architecture document; records external review correcting `zero chance` language to `structurally minimized`. |
| `Memory_Alpha_v4.2_Sovereign_State.docx` | 21,663 | `9edbd2865bea71ab26d04f19e8704fdf84df2c90a66082d19e4fbb295a0179d5` | new in this tranche | Sovereign State v4.2 branch. |
| `Memory_Alpha_v4.1_Sovereign_State.docx` | 20,871 | `8a16727b13a2619a362123ed7f9d32ec451cf5190ce2e36575334362a12a2e66` | new in this tranche | Sovereign State v4.1 branch; includes known-limitations discipline. |
| `memory alpha v3 gemini.txt` | 2,251 | `022573903f08634efb7b5ac5c48b76f76290d65269bcabfc5308bf573c0a3bd3` | new in this tranche | Compact Gemini-era v3 synopsis with legacy citation placeholders. |
| `Memory_Alpha_v3.docx` | 22,682 | `fec587419e67cd4c2ac9780faee6f93dc5adc9df0b6cd82b54bfda5acbfaf0e1` | new in this tranche | Internally Version 3.0. |
| `Memory_Alpha_v3 (1).docx` | 15,887 | `1fc58fb9b762c611e8dadcc7087224b692b7bc32d77772b958461c1141e0f84c` | new in this tranche | Filename says v3; internally Version 2.0. Distinct intermediate variant. |
| `Memory_Alpha_v2.docx` | 15,456 | `3f730d77e0ba273592b817c40b9396396fd9844fa430119e6c96b5b31fa22c5e` | new in this tranche | Internally Version 2.0; earlier Student A/B assignment differs from later documents. |
| `MEMORY_ALPHA_V15_INTEGRATED_SUITE.zip(2).sha256` | 104 | `a6060360588163013b1f2b92ea7adbc4e92620955561e0fa5cf37c7e876612cc` | duplicate already preserved | same bytes as prior tranche SHA file |

## V15 closure

The uploaded `MEMORY_ALPHA_V15_INTEGRATED_SUITE(1).zip` has SHA-256:

`a3e509f70a285ca8d1a0946deef99498de3abf235b23b613dc4e9c7eac5f08a7`

That is the exact value previously pinned by the archived V15 checksum file. The actual suite is therefore now preserved under:

`../../releases/MA-SUITE-2026.15/`

with its public README exposed for ordinary GitHub reading and the original ZIP retained for byte-level provenance.

## Claim discipline

This tranche contains historically important overclaims: categorical FOOM language, asserted GDPR/legal effects, model-generated performance multipliers, economic projections, and unverified empirical claims.

They remain visible because the correction trajectory matters. A historical hash proves **what bytes existed**, not that the assertions in those bytes were true.
