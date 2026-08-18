-- Checkpoint 6 prerequisite: lexical search over chunks.
--
-- Checkpoint 3 searches `pages`, checkpoint 5 searches `chunks`. Fusing two
-- rankings requires both to rank the *same* objects, otherwise "rank 3" means
-- different things on each side and the combined score is meaningless. Giving
-- chunks their own tsvector puts both retrievers on one unit.
--
-- Chunk-level FTS is also better on its own terms: ts_rank_cd normalizes by
-- length, and a 433-token chunk is a far tighter denominator than a 4,000-
-- character page, so precise short matches stop being buried.
--
-- APPLY ONLY WHEN radonc/embed.py IS NOT RUNNING. Adding a STORED generated
-- column rewrites the table under an ACCESS EXCLUSIVE lock, which would block
-- every UPDATE the embedding job issues -- and that job runs for two hours.

ALTER TABLE chunks
    ADD COLUMN IF NOT EXISTS tsv tsvector
    GENERATED ALWAYS AS (to_tsvector('english', content)) STORED;

CREATE INDEX IF NOT EXISTS idx_chunks_tsv ON chunks USING GIN (tsv);
