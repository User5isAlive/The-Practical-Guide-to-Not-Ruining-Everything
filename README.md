# The Practical Guide to Not Ruining Everything

## Memory Alpha / Companion Light

An experimental research repository for **user-sovereign persistent AI memory**, **model-agnostic orchestration**, and **adversarial multi-model engineering**.

> **Status: research prototype.** Nothing in this repository should be treated as security-audited, legally certified, or experimentally proven unless the relevant item is explicitly marked **VERIFIED** in the defect ledger.

The project began with solo D&D: could one person sustain a good campaign with an LLM as game master and storyteller, remembering obligations, world state, and prior choices across sessions and model changes? That grew into a question about keeping continuity, preferences, history, and consent under the user’s control while treating models as replaceable cognitive services. It has since evolved into **Companion Light**, a mobile reference architecture, and the **Cathedral Method**, a development process built around independent review, persistent defect tracking, diffs, compilers, and tests.

### Start here

- **Current architecture (v17.1):** [projects/companion-light/v17.1/01_FOR_THE_MONKEY.md](projects/companion-light/v17.1/01_FOR_THE_MONKEY.md)
- **Pseudocode:** [projects/companion-light/v17.1/02_PSEUDOCODE.md](projects/companion-light/v17.1/02_PSEUDOCODE.md)
- **Engineering method:** [projects/companion-light/v17.1/03_PROCESS.md](projects/companion-light/v17.1/03_PROCESS.md)
- **Latest implementation delta (v17.2):** [projects/companion-light/v17.2/README.md](projects/companion-light/v17.2/README.md)
- **Latest defect ledger:** [projects/companion-light/v17.2/DEFECTS.md](projects/companion-light/v17.2/DEFECTS.md)
- **Project history:** [docs/HISTORY.md](docs/HISTORY.md)
- **Current status and claim discipline:** [docs/STATUS.md](docs/STATUS.md)

### Run the corpus foundation

The new local importer turns supported conversation exports into attributed, searchable context. Try the synthetic campaign without a model or API key:

```sh
mkdir -p private
python3 tools/corpus.py --db private/corpus.sqlite import examples/campaign.json --provider other --format normalized
python3 tools/corpus.py --db private/corpus.sqlite search "Aeliana blacksmith debt"
python3 -m unittest discover -s tests -v
```

See [corpus import instructions](docs/CORPUS.md), the [pocket/home target](docs/POCKET_PORTAL.md), and [trust-profile compatibility](docs/TRUST_PROFILES.md). The staging database is plaintext and has no authority or automatic vault writeback.

The full [v17.1 iOS/Android source](projects/companion-light/v17.1/) has been restored verbatim from the supplied archive. v17.2 remains a partial delta, not a complete buildable tree. See the [engineering review](docs/ENGINEERING_REVIEW_2026-09-07.md).

### Current working idea

The enduring relationship lives in a user-controlled memory/persona layer. Models remain replaceable. A local companion retrieves context, routes work, and presents one user-facing voice while frontier systems can be called as external specialists.

The present Companion Light design separates:

**Vault → Librarian → Judge/Router → optional frontier committee → Spread → Voice**

with provenance tracked separately from truth, model-written continuity separated from evidence grounding, and owner-controlled promotion/erasure.

### The Cathedral Method

The engineering process now uses:

**English theorem → pseudocode → canonical code → build → test → blind peer review → defect ledger → minimal patch**

The central lesson is simple: a model saying a fix exists is not evidence that the fix exists. The repository, diff, compiler, test output, and defect ledger are the shared medium.

### Repository map

```text
projects/companion-light/   current reference implementation, deltas, and specifications
docs/                       history, status, and process notes
archive/                    earlier Memory Alpha material preserved for provenance
archive/corpus/             historical RAG corpus chunks
archive/research/           older research/specification artifacts
archive/media/              historical media artifacts
```

### Historical material

Earlier documents are intentionally preserved because the evolution matters. Some contain stronger claims than the current project would make today—for example categorical statements about alignment, FOOM prevention, or legal compliance. They are **historical artifacts, not current guarantees**. See [docs/HISTORY.md](docs/HISTORY.md).

### License intent

Original project material is offered under **CC0 1.0** unless a file says otherwise. Third-party material, model outputs, attachments, and media may carry separate rights or platform terms; users are responsible for checking them before reuse.

---

Built in public, including the mistakes.
