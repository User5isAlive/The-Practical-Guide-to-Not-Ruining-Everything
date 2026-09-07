# Importing the next year of conversations

`tools/corpus.py` stages conversation exports locally and searches them with SQLite
FTS5. Python 3.10+ with SQLite FTS5 is the only dependency. It makes no network calls.
This is a working import/retrieval utility, not an encrypted vault, mobile integration,
semantic search engine, or proof that retrieved statements are true.

## Try the synthetic campaign

Run from the repository root:

```sh
mkdir -p private
python3 tools/corpus.py --db private/corpus.sqlite import examples/campaign.json --provider other --format normalized
python3 tools/corpus.py --db private/corpus.sqlite search 'Aeliana blacksmith debt'
python3 -m unittest discover -s tests -v
```

The database and FTS index contain plaintext. Keep them on storage you control;
`private/` and database files are ignored by Git. The ignore rules do not encrypt,
redact, or remove already tracked historical files. Do not commit a new personal
export, genetics file, or licensed rulebook as a code fixture. The synthetic campaign
has no dependency on a commercial D&D book.

## Supported input contracts

| Format | Provider flag | Accepted shape |
|---|---|---|
| `chatgpt` | `openai` | JSON conversation list with `mapping` and `current_node`; text messages along the selected parent chain only |
| `claude` | `anthropic` | JSON conversation list with `uuid`, `chat_messages`, message `uuid`, `sender`, and `text` |
| `normalized` | any listed provider | Explicit `ma-corpus-v1` interchange shown in `examples/campaign.json` |
| `text` | any listed provider | UTF-8 legacy text; role remains `unknown` regardless of embedded role labels |

These adapters target the stated shapes, not every export version. ChatGPT non-text
messages and Claude attached files cause the entire import to roll back. Convert
such exports deliberately to normalized text before importing. Gemini HTML/Takeout,
images, audio, attachment extraction, and the older third-party `Prompt`/`Response`
export format are not automatic adapters yet. Use normalized JSON for Google/Gemini
records rather than pretending an unexamined export format is supported.

```sh
python3 tools/corpus.py --db private/corpus.sqlite import /path/to/conversations.json --provider openai --format chatgpt
python3 tools/corpus.py --db private/corpus.sqlite import /path/to/claude.json --provider anthropic --format claude
python3 tools/corpus.py --db private/corpus.sqlite import /path/to/gemini-normalized.json --provider google --format normalized
```

## Provenance and revisions

Each import has a digest of the original file, its provider label, parser format,
and chunking configuration. Each record keeps conversation ID, message ID, role,
provider, and exact character offsets into decoded message text. Offsets are Unicode
codepoints, **not original-file byte offsets**. Keep the original exports privately;
the file digest does not reconstruct them or authenticate their author.

Repeated identical imports are no-ops. Overlapping exports share identical records.
Changed messages create new record revisions; old text is not silently overwritten.
Source links preserve which exports contain each record. Search defaults to all
imported revisions, which can include contradictory or superseded statements. Use
`--source-id` with the ID returned by import to search one snapshot only.

Every record has `authority=NONE`. Imported `user`/`system` labels are claims in an
export, not owner authentication, live instructions, or T1 attestation. This tool
never writes the mobile vault and does not translate historical T0–T4 labels.

## Retrieval receipts and limits

Search returns exact stored text, source hashes, identifiers, BM25 ranks, and up to
three near-misses. It searches the FTS index instead of loading the corpus on every
query. Query punctuation is treated as input data, not FTS operators. This is lexical
OR matching, limited to 64 query terms; paraphrases with no matching words can be
missed. A near-miss is another lexical result, not an exhaustive account of omissions.

Chunking is deterministic and lossless within each decoded message. Large messages
split at a configurable character limit (default 1,600); there is no semantic boundary
or overlap yet. Import reads one export into RAM, so it is not a streaming importer
for arbitrarily large files. Empty text produces no retrieval record. Unsupported
shapes abort atomically instead of leaving a half-imported source.

Next integration gate: select reviewed spans, preserve this provenance, and stage them
through an explicit vault importer. Do not map all imported user messages to T1-O.
