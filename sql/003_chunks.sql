-- Checkpoint 4b: chunking.
--
-- Pulled ahead of the vector store because MedCPT reads 512 tokens and the median
-- page in this corpus is 949. Embedding pages directly would truncate 86.6% of
-- them and discard 53% of the corpus, silently.
--
-- Chunks span the *document*, not the page. Prose runs across page breaks, so
-- chunking inside page boundaries would cut a sentence in half roughly 24,000
-- times. Citations still work because each chunk records the page range it covers
-- -- "pp. 14-15" is a true citation, whereas pinning a page-spanning chunk to a
-- single page number would not be.

CREATE TABLE IF NOT EXISTS chunks (
    id           BIGSERIAL PRIMARY KEY,
    document_id  BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index  INT NOT NULL,          -- 0-based, ordinal within the document
    content      TEXT NOT NULL,
    token_count  INT NOT NULL,          -- measured with MedCPT's own tokenizer

    -- Inclusive 1-based page range, for provenance. Equal when a chunk sits
    -- wholly inside one page, which is the common case.
    start_page   INT NOT NULL,
    end_page     INT NOT NULL,

    UNIQUE (document_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS idx_chunks_document_id ON chunks (document_id);

-- The embedding column and its HNSW index belong to checkpoint 5; adding a
-- nullable column later is a metadata-only change, so there is nothing to gain
-- by declaring it before there are vectors to put in it.
