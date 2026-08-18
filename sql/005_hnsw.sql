-- Checkpoint 5, part 2: the vector index. Apply only after radonc/embed.py has
-- filled every embedding -- see sql/004_embeddings.sql for why it is separate.
--
-- vector_cosine_ops, not vector_ip_ops: embeddings are L2-normalized at encode
-- time, so cosine and inner product rank identically, but cosine reports a
-- bounded distance in [0, 2] that is far easier to reason about and to threshold.
--
-- HNSW is an *approximate* index. It trades recall for speed:
--   m                = edges per node (higher: better recall, bigger index)
--   ef_construction  = candidate list while building (higher: better graph, slower build)
--   hnsw.ef_search   = candidate list while querying (runtime knob, see below)
-- m=16/ef_construction=64 are pgvector's defaults and are a sane starting point
-- at this corpus size; tune only against the evaluation set, never by feel.

SET maintenance_work_mem = '1GB';   -- session-scoped; an under-resourced build spills to disk and crawls

CREATE INDEX IF NOT EXISTS idx_chunks_embedding_hnsw
    ON chunks USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

ANALYZE chunks;

-- Query-time recall knob, set per session by the search code rather than here:
--   SET hnsw.ef_search = 100;   -- default 40; raise for recall, lower for speed
