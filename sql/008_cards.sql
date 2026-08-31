-- Checkpoint 11: vera-learn — flashcards grounded in the corpus.
--
-- Cards come from Anki decks; the corpus decides which of them are usable. Rather
-- than curating decks by name, every text-only card is imported and scored
-- against the index, and `best_distance` decides what can be quizzed. That keeps
-- the selection measurable: "cards this corpus can support" is a number, not an
-- opinion about which deck looks relevant.
--
-- Measured on 14,204 notes: half are text-only, and of those roughly 43% ground
-- at cosine distance <= 0.34 -- but that average spans 87% for radiation oncology
-- decks and ~15% for diagnostic radiology and nursing oncology, which the corpus
-- simply does not cover.

CREATE TABLE IF NOT EXISTS cards (
    id            BIGSERIAL PRIMARY KEY,
    deck          TEXT NOT NULL,
    note_id       BIGINT,
    front         TEXT NOT NULL,
    back          TEXT NOT NULL,

    -- sha256 of front+back. Decks overlap heavily -- "Breast T1" appears in both
    -- Cancer_Staging and Radiation_Oncology_Comprehensive -- and a learner should
    -- not be asked the same question twice because two packs shared a source.
    fingerprint   CHAR(64) NOT NULL UNIQUE,

    -- Filled by `vera.quiz --ground`. NULL means not yet scored.
    best_distance REAL,
    grounded_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_cards_deck ON cards (deck);
CREATE INDEX IF NOT EXISTS idx_cards_groundable
    ON cards (best_distance) WHERE best_distance IS NOT NULL;

-- The passages backing a card, best first. Kept rather than recomputed: grounding
-- 7,000 cards costs GPU time, and a quiz session should be able to show its
-- evidence instantly.
CREATE TABLE IF NOT EXISTS card_citations (
    card_id   BIGINT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    chunk_id  BIGINT NOT NULL REFERENCES chunks(id) ON DELETE CASCADE,
    rank      INT NOT NULL,
    distance  REAL NOT NULL,
    PRIMARY KEY (card_id, rank)
);

CREATE INDEX IF NOT EXISTS idx_card_citations_card ON card_citations (card_id);
