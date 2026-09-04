# v17.2 source manifest

Artifacts supplied with the v17.2 iteration:

| Artifact | SHA-256 | Notes |
|---|---|---|
| `v17_1_to_v17_2.patch` | `8a15e0bdac130aedca5bbaa8efe9de8588cc1410a29cdcce81b040461650e3da` | 34,468-byte textual delta |
| `MLXRuntime.swift` | `0a31588ad9c44afab35cee1fc8c8f4a94ef5b4c6aa793a3ea1cab539c398a5b7` | iOS MLX + EmbeddingGemma adapter |
| `LocalRuntime.kt` | `d88927538ce7534ec5e76c43b4202bd2a79b44e62cfdf9d3534e350fe2efeb0c` | Android LiteRT-LM + embedding adapter |
| `DEFECTS.md` | `67c6a0508a3efbc4741696787ded08fb2ec3fd15013bbc70ba00e8466216e10e` | ledger through CAT-028 |
| `reorganize.bundle` | `3c96a7c8c89f94be4eb20176f500de76e52b59a203c8c9b5caf227a7b7813ca9` | 33,253,137-byte Git bundle; transport artifact, not nested in repo |

Bundle refs/lineage observed locally:

```text
2285b431a3d62bfe2edb38a2ce99dc5f51e7f7cc  v17.2 adapters/candidate-pool commit
└─ 92c14c0627fe0de6b81efad1d3991b1e894cc36e  python README status-stamp repair
   └─ 4b2860ee1d1723db18a766772ffa27d12715d68a  repository reorganization
      └─ ff15bd0db05830e87dca2cd6ab65ac0f0478f83f  original public main prerequisite
```

The bundle is intentionally treated as a transport/archive object. Git history and current source should live as normal commits/files rather than as a git repository nested inside itself.
