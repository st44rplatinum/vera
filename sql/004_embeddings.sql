-- Checkpoint 5: radonc-vector-search.
--
-- The column is added here; the HNSW index is NOT. Building an index on an empty
-- table and then inserting 65k rows makes Postgres maintain the graph on every
-- insert, which is far slower than bulk-loading and indexing once at the end.
-- See sql/005_hnsw.sql, applied after radonc/embed.py finishes.

ALTER TABLE chunks ADD COLUMN IF NOT EXISTS embedding vector(768);

-- Lets the embedding job find its remaining work instantly on resume. Partial
-- index, so it costs nothing once every row is populated -- it shrinks to empty.
CREATE INDEX IF NOT EXISTS idx_chunks_pending_embedding
    ON chunks (id) WHERE embedding IS NULL;
