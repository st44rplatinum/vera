-- Checkpoint 2: radonc-db
-- Applied automatically on first container boot (mounted at
-- /docker-entrypoint-initdb.d). To re-apply after edits, see scripts/apply_sql.sh.

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;   -- unused until checkpoint 5; free to enable now

CREATE TABLE IF NOT EXISTS documents (
    id          BIGSERIAL PRIMARY KEY,
    filename    TEXT NOT NULL,
    -- Content hash, not filename, is the identity of a document: the same NCCN PDF
    -- downloaded twice under different names must not become two documents.
    sha256      CHAR(64) NOT NULL UNIQUE,
    title       TEXT,
    page_count  INT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pages (
    id           BIGSERIAL PRIMARY KEY,
    document_id  BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    page_number  INT NOT NULL,           -- 1-based, matches what a human sees in a viewer
    content      TEXT NOT NULL,
    char_count   INT NOT NULL,

    tsv tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,

    UNIQUE (document_id, page_number)
);

-- Lexical search (checkpoint 3) reads this.
CREATE INDEX IF NOT EXISTS idx_pages_tsv ON pages USING GIN (tsv);

-- Fuzzy matching for typo'd queries ("hipocampal avoindance"). Deliberately on
-- title only: a GIN trigram index over full page text explodes in size and build
-- time, and typo tolerance belongs on short strings you're matching whole.
CREATE INDEX IF NOT EXISTS idx_documents_title_trgm
    ON documents USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_pages_document_id ON pages (document_id);
