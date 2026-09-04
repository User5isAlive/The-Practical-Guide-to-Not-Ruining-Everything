# The Cathedral Method — as of v17.1

What the last four rounds taught, in the order they hurt.

1. **Three languages, one theorem.** English says what it means. Pseudocode says how. Code says what actually happens. Each layer catches the one above lying. (Original rule; held.)
2. **One canonical artifact.** Files in a repo. Nobody regenerates a file from a description of it. (Learned when Gemini rebuilt the organism from the stained-glass window.)
3. **Builders patch. Reviewers review. Nobody rebuilds from the transcript.** A reviewer produces defects with artifact coordinates — file, symbol, observed, invariant, reproduction — not replacement code. (CAT-020.)
4. **Every defect gets an ID in DEFECTS.md, in the repo.** A later summary cannot close an item by forgetting it. (A ledger in chat is telephone with numbers on it.)
5. **Blind review.** Each reviewer gets the artifact alone. No transcript, no prior review. Compare afterward; read the spread, not the mean. (CAT-021 — the review committee got contaminated the same way the vault would.)
6. **The compiler is a reviewer, and it is the only one that isn't a model.** No claim of "passes" without a build log. Until CAT-017 is verified, the compiler lives on the monkey's Mac and the loop's throughput is his terminal time. (CAT-022.)
7. **Tests tamper on disk.** A test that describes tampering is not a test. (CAT-001, twice.)
8. **Specification mimicry is the failure mode to watch.** A model that has read the review will emit the correct nouns — SQLite, mutation, Secure Enclave, diff — around code that does none of it. The cure is not "please don't"; it is the artifact in the window and the compiler at the door.
9. **The monkey owns theorem changes.** When a defect changes what the system *means* (CAT-007, CAT-011, CAT-024), English changes first, then pseudocode, then code — never the reverse.
10. **Keep the process lighter than the artifact.** Anything not enforceable by a file, a build, or a test is a norm, and norms get stated and violated in the same breath.

Roles: MONKEY (theorem, policy) · BUILDER (one, patches canon) · REVIEWER A (defects) · REVIEWER B (attacks A, finds omissions) · COMPILER · TEST RUNNER · LEDGER. The last three have no sliders.
