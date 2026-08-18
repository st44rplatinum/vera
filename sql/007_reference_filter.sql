-- Exclude bibliography chunks from retrieval.
--
-- Reference lists are the densest topical text in any paper -- a xerostomia
-- bibliography contains "xerostomia", "radiotherapy" and "head and neck" a dozen
-- times each -- so they rank highly on both retrievers while containing no
-- findings at all. Searching "dry mouth after radiation" returned two bibliography
-- pages as the top two hits before this.
--
-- The pattern matches numbered citation entries with author initials
-- ("12. Coles CE, Griffin CL, ..."), requiring at least four in one chunk.
--
-- Two heuristics were tried. Keyword density (>=5 "et al" AND >=6 years) matched
-- 5.2% of chunks but caught related-work prose -- a paragraph discussing FlowNet
-- was flagged, and that is exactly the kind of passage someone might search for.
-- This pattern matches 13.9% and was clean on every sample checked, because
-- numbered-entry-plus-initials is a shape that only appears in a reference list.
--
-- Generated and STORED rather than computed per query: the regex is far too slow
-- to run over 65k chunks at search time.
--
-- APPLY ONLY WHEN radonc/embed.py IS NOT RUNNING -- ACCESS EXCLUSIVE lock.

ALTER TABLE chunks
    ADD COLUMN IF NOT EXISTS is_reference BOOLEAN
    GENERATED ALWAYS AS (
        regexp_count(content, '[0-9]+\. [A-Z][a-zA-Z-]+ [A-Z]{1,3}[,.]') >= 4
    ) STORED;

-- Partial indexes over the searchable subset, so the filter costs nothing to apply.
CREATE INDEX IF NOT EXISTS idx_chunks_tsv_content
    ON chunks USING GIN (tsv) WHERE NOT is_reference;
