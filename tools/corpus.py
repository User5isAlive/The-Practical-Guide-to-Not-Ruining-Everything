#!/usr/bin/env python3
"""CC0-1.0. Local, non-authoritative conversation staging and FTS5 retrieval.

This is NOT the encrypted Companion vault. No network, model, or promotion path.
All input metadata is an export claim, never authentication or permission.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import sqlite3
from pathlib import Path

SCHEMA = 'ma-corpus-v1'
PROVIDERS = ('openai', 'anthropic', 'google', 'other')
ROLES = ('user', 'assistant', 'system', 'tool', 'unknown')


def digest(value):
    return hashlib.sha256(value.encode('utf-8') if isinstance(value, str) else value).hexdigest()


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'))


def require_string(value, field):
    if not isinstance(value, str) or not value:
        raise ValueError(f'{field} must be a nonempty string')
    return value


def normalized_messages(data):
    """Explicit interchange format, also used for converted Gemini exports."""
    if not isinstance(data, dict) or data.get('schema') != SCHEMA:
        raise ValueError(f'expected schema {SCHEMA}')
    conversations = data.get('conversations')
    if not isinstance(conversations, list):
        raise ValueError('conversations must be a list')
    for c in conversations:
        cid = require_string(c.get('id'), 'conversation id')
        if not isinstance(c.get('messages'), list):
            raise ValueError('messages must be a list')
        for m in c['messages']:
            mid = require_string(m.get('id'), 'message id')
            if m.get('role') not in ROLES or not isinstance(m.get('text'), str):
                raise ValueError('each message needs a recognized role and text string')
            yield cid, mid, m['role'], m['text']


def chatgpt_messages(data):
    """Only the selected branch; sibling regenerations must not become history."""
    if not isinstance(data, list):
        raise ValueError('ChatGPT export must be a conversation list')
    for c in data:
        cid = require_string(c.get('id') or c.get('conversation_id'), 'conversation id')
        mapping = c.get('mapping')
        if not isinstance(mapping, dict) or c.get('current_node') not in mapping:
            raise ValueError('ChatGPT mapping/current_node missing; export branch is ambiguous')
        node, visited, chain = c['current_node'], set(), []
        while node is not None:
            if node in visited or node not in mapping:
                raise ValueError('broken or cyclic ChatGPT parent chain')
            visited.add(node)
            entry = mapping[node]
            chain.append((node, entry.get('message')))
            node = entry.get('parent')
        for node, m in reversed(chain):
            if not m:
                continue
            content = m.get('content', {})
            parts = content.get('parts', [])
            # Refuse unsupported content rather than silently losing image/audio context.
            if content.get('content_type') != 'text' or not all(isinstance(p, str) for p in parts):
                raise ValueError('non-text ChatGPT message: convert to explicit normalized text first')
            role = m.get('author', {}).get('role', 'unknown')
            yield cid, str(m.get('id') or node), role if role in ROLES else 'unknown', '\n'.join(parts)


def claude_messages(data):
    if not isinstance(data, list):
        raise ValueError('Claude export must be a conversation list')
    for c in data:
        cid = require_string(c.get('uuid'), 'conversation uuid')
        if not isinstance(c.get('chat_messages'), list):
            raise ValueError('chat_messages must be a list')
        for m in c['chat_messages']:
            mid = require_string(m.get('uuid'), 'message uuid')
            if not isinstance(m.get('text'), str):
                raise ValueError('Claude message needs text')
            if m.get('attachments') or m.get('files'):
                raise ValueError('Claude attachments require explicit normalized conversion')
            role = {'human': 'user', 'assistant': 'assistant'}.get(m.get('sender'), 'unknown')
            yield cid, mid, role, m['text']


def chunks(text, limit):
    """Contiguous Unicode-codepoint spans, lossless even for oversized messages."""
    if limit < 1:
        raise ValueError('chunk size must be positive')
    for start in range(0, len(text), limit):
        yield start, min(start + limit, len(text)), text[start:start + limit]


def connect(path):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.execute('PRAGMA foreign_keys=ON')
    version = db.execute('PRAGMA user_version').fetchone()[0]
    if version not in (0, 1):
        db.close()
        raise ValueError('unsupported corpus database version')
    if version == 0 and db.execute("SELECT 1 FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'").fetchone():
        db.close()
        raise ValueError('refusing to initialize a non-corpus database')
    db.executescript('''
      CREATE TABLE IF NOT EXISTS sources (
        id TEXT PRIMARY KEY, provider TEXT NOT NULL, format TEXT NOT NULL,
        sha256 TEXT NOT NULL, chunk_chars INTEGER NOT NULL);
      CREATE TABLE IF NOT EXISTS records (
        id TEXT PRIMARY KEY, provider TEXT NOT NULL, conversation_id TEXT NOT NULL,
        message_id TEXT NOT NULL, role TEXT NOT NULL, start_char INTEGER NOT NULL,
        end_char INTEGER NOT NULL, text TEXT NOT NULL,
        authority TEXT NOT NULL CHECK(authority = 'NONE'));
      CREATE TABLE IF NOT EXISTS source_records (
        source_id TEXT REFERENCES sources(id), record_id TEXT REFERENCES records(id),
        ordinal INTEGER NOT NULL, PRIMARY KEY(source_id, ordinal));
      CREATE INDEX IF NOT EXISTS record_sources ON source_records(record_id);
      CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
        text, content='records', content_rowid='rowid');
      CREATE TRIGGER IF NOT EXISTS records_insert AFTER INSERT ON records BEGIN
        INSERT INTO search_index(rowid,text) VALUES(new.rowid,new.text);
      END;
      PRAGMA user_version=1;
    ''')
    return db


def ingest(db, path, provider, fmt, chunk_chars=1600):
    if provider not in PROVIDERS or chunk_chars < 1:
        raise ValueError('invalid provider or chunk size')
    if (fmt == 'chatgpt' and provider != 'openai') or (fmt == 'claude' and provider != 'anthropic'):
        raise ValueError('export format/provider mismatch')
    if fmt not in ('chatgpt', 'claude', 'normalized', 'text'):
        raise ValueError('unknown format')
    raw = Path(path).read_bytes()
    source_hash = digest(raw)
    source_id = digest(canonical([SCHEMA, provider, fmt, source_hash, chunk_chars]))
    if db.execute('SELECT 1 FROM sources WHERE id=?', (source_id,)).fetchone():
        return {'source_id': source_id, 'added': 0, 'already_imported': True}
    text = raw.decode('utf-8-sig')
    if fmt == 'text':
        # Flat legacy chunks have lost reliable message boundaries. Never infer owner trust.
        messages = [(source_hash, 'document', 'unknown', text)]
    else:
        parser = {'chatgpt': chatgpt_messages, 'claude': claude_messages,
                  'normalized': normalized_messages}[fmt]
        messages = parser(json.loads(text))
    count, ordinal, identities = 0, 0, set()
    with db:
        db.execute('INSERT INTO sources VALUES(?,?,?,?,?)',
                   (source_id, provider, fmt, source_hash, chunk_chars))
        for cid, mid, role, body in messages:
            if (cid, mid) in identities:
                raise ValueError('duplicate message identity within export')
            identities.add((cid, mid))
            body_hash = digest(body)
            for start, end, span in chunks(body, chunk_chars):
                # Include whole-message digest so edited messages cannot be silently spliced.
                rid = digest(canonical([SCHEMA, provider, cid, mid, role, body_hash, start, end]))
                result = db.execute('INSERT OR IGNORE INTO records VALUES(?,?,?,?,?,?,?,?,?)',
                                    (rid, provider, cid, mid, role, start, end, span, 'NONE'))
                count += result.rowcount
                db.execute('INSERT INTO source_records VALUES(?,?,?)', (source_id, rid, ordinal))
                ordinal += 1
    return {'source_id': source_id, 'added': count, 'already_imported': False}


def search(db, question, limit=5, source_id=None):
    if not 1 <= limit <= 100:
        raise ValueError('limit must be between 1 and 100')
    tokens = re.findall(r'\w+', question, re.UNICODE)[:64]
    if not tokens:
        return {'authority': 'NONE', 'plane': 'context', 'returned': [], 'near_misses': []}
    query = ' OR '.join('"' + token + '"' for token in tokens)
    params = [query]
    scope = ''
    if source_id is not None:
        if not db.execute('SELECT 1 FROM sources WHERE id=?', (source_id,)).fetchone():
            raise ValueError('unknown source id')
        scope = ' AND EXISTS (SELECT 1 FROM source_records s WHERE s.record_id=r.id AND s.source_id=?)'
        params.append(source_id)
    rows = db.execute('''SELECT r.*, bm25(search_index) AS rank FROM search_index
        JOIN records r ON r.rowid=search_index.rowid WHERE search_index MATCH ?'''
        + scope + ' ORDER BY rank, r.id LIMIT ?', (*params, limit + 3)).fetchall()
    hits = []
    for row in rows:
        hit = dict(row)
        hit['sources'] = [dict(s) for s in db.execute('''SELECT sources.id, sources.sha256
          FROM sources JOIN source_records s ON s.source_id=sources.id
          WHERE s.record_id=? ORDER BY sources.id''', (row['id'],))]
        hits.append(hit)
    return {'authority': 'NONE', 'plane': 'context', 'returned': hits[:limit],
            'near_misses': hits[limit:], 'cutoff': 'count_limit' if len(hits) > limit else 'matches_exhausted',
            'scope': source_id or 'all_imported_revisions', 'ranking': 'FTS5 BM25; lower is better'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db', required=True, type=Path, help='private staging SQLite path (unencrypted)')
    sub = parser.add_subparsers(dest='command', required=True)
    imp = sub.add_parser('import')
    imp.add_argument('path', type=Path)
    imp.add_argument('--provider', choices=PROVIDERS, required=True)
    imp.add_argument('--format', choices=('chatgpt', 'claude', 'normalized', 'text'), required=True)
    imp.add_argument('--chunk-chars', type=int, default=1600)
    qry = sub.add_parser('search')
    qry.add_argument('question')
    qry.add_argument('--limit', type=int, default=5)
    qry.add_argument('--source-id', help='restrict to one import snapshot; avoids mixing revisions')
    args = parser.parse_args()
    try:
        if args.command == 'search' and not args.db.is_file():
            raise ValueError('database does not exist')
        with connect(args.db) as db:
            result = (ingest(db, args.path, args.provider, args.format, args.chunk_chars)
                      if args.command == 'import' else search(db, args.question, args.limit, args.source_id))
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except (ValueError, OSError, sqlite3.Error, KeyError, TypeError, AttributeError) as error:
        parser.exit(2, f'corpus: {error}\n')


if __name__ == '__main__':
    main()
