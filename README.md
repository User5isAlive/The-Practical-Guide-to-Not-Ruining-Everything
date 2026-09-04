# The Practical Guide to Not Ruining Everything

## Memory Alpha / Companion Light

An experimental research repository for **user-sovereign persistent AI memory**, **model-agnostic orchestration**, and **adversarial multi-model engineering**.

> **Status: research prototype.** Nothing in this repository should be treated as security-audited, legally certified, or experimentally proven unless the relevant item is explicitly marked **VERIFIED** in the defect ledger.

The project began as a question: can a person keep continuity, preferences, history, and consent under their own control while treating frontier models as replaceable cognitive services? It has since evolved into **Companion Light**, a mobile reference architecture, and the **Cathedral Method**, a development process built around independent review, persistent defect tracking, diffs, compilers, and tests.

### Start here

- **Current architecture (v17.1):** [projects/companion-light/v17.1/01_FOR_THE_MONKEY.md](projects/companion-light/v17.1/01_FOR_THE_MONKEY.md)
- **Pseudocode:** [projects/companion-light/v17.1/02_PSEUDOCODE.md](projects/companion-light/v17.1/02_PSEUDOCODE.md)
- **Engineering method:** [projects/companion-light/v17.1/03_PROCESS.md](projects/companion-light/v17.1/03_PROCESS.md)
- **Latest implementation delta (v17.2):** [projects/companion-light/v17.2/README.md](projects/companion-light/v17.2/README.md)
- **Latest defect ledger:** [projects/companion-light/v17.2/DEFECTS.md](projects/companion-light/v17.2/DEFECTS.md)
- **Who the human is—and is not:** [docs/ABOUT_THE_MONKEY.md](docs/ABOUT_THE_MONKEY.md)
- **Project history:** [docs/HISTORY.md](docs/HISTORY.md)
- **Current status and claim discipline:** [docs/STATUS.md](docs/STATUS.md)

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
docs/                       history, status, authorship, and process notes
archive/history/            reader-oriented development history + exact source tranches
archive/corpus/             historical RAG corpus chunks
archive/research/           older research/specification artifacts
archive/media/              historical media artifacts
```

### Historical material

Earlier documents are intentionally preserved because the evolution matters. Some contain stronger claims than the current project would make today—for example categorical statements about alignment, FOOM prevention, legal compliance, or model-generated performance metrics. They are **historical artifacts, not current guarantees**. See [docs/HISTORY.md](docs/HISTORY.md) and [archive/history/README.md](archive/history/README.md).

### A note on authorship and model write access

This is not the work product of a hidden AI lab or credentialed multidisciplinary research team. The human project owner describes himself, usefully if impolitely, as **“a monkey with a credit card and a computer.”** The archive makes the human/model division of labor explicit.

On **September 4, 2026**, the human deliberately granted connected frontier models write access to this GitHub repository. From that point onward, models could directly create repository artifacts through the GitHub integration when authorized. See [docs/ABOUT_THE_MONKEY.md](docs/ABOUT_THE_MONKEY.md).

### License intent

Original project material is offered under **CC0 1.0** unless a file says otherwise. Third-party material, model outputs, attachments, and media may carry separate rights or platform terms; users are responsible for checking them before reuse.

---

Built in public, including the mistakes.
