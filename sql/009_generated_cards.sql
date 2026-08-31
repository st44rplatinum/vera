-- Checkpoint 11b: flashcards written from the corpus rather than matched to it.
--
-- Grounding imported Anki cards against this corpus failed, and measurement said
-- why. Of cards passing the bi-encoder distance threshold, ~4% were actually
-- supported by their top passage; adding MedCPT's cross-encoder raised that only
-- to ~8%. The reranker was working -- it correctly reported that nothing
-- supported those cards. The corpus simply does not contain the answers.
--
-- It could not. The imported decks ask for AJCC staging definitions, ICRP dose
-- limits, chemotherapy regimens and professional-body governance. This corpus is
-- 2,416 research papers; papers report studies, they do not define N2 staging.
--
-- Inverting the direction removes the problem rather than fighting it. A card
-- written *from* a passage is supported by that passage by construction, and the
-- material research papers do contain -- trial outcomes, toxicity rates,
-- technique comparisons, dose-response -- is exactly what a learner needs.
--
-- `support_score` is the cross-encoder rating the generated question against the
-- passage it came from. Generation can still drift, and a question its own source
-- cannot answer is worth catching.

CREATE TABLE IF NOT EXISTS generated_cards (
    id            BIGSERIAL PRIMARY KEY,
    chunk_id      BIGINT NOT NULL REFERENCES chunks(id) ON DELETE CASCADE,
    question      TEXT NOT NULL,
    answer        TEXT NOT NULL,
    support_score REAL,
    model         TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (chunk_id, question)
);

CREATE INDEX IF NOT EXISTS idx_generated_cards_chunk ON generated_cards (chunk_id);
CREATE INDEX IF NOT EXISTS idx_generated_cards_supported
    ON generated_cards (support_score DESC);
