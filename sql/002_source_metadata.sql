-- Provenance for retrieved passages.
--
-- A search hit in this domain is only actionable if the user (or the model, at
-- checkpoint 8) can cite where it came from. "Page 14 of some PDF" is not a
-- citation; "J Thorac Dis 2026, doi:10.xxxx, p.14" is.

ALTER TABLE documents ADD COLUMN IF NOT EXISTS pmcid   TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS doi     TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS journal TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS pubdate TEXT;   -- PMC returns free text ("2026 Aug 7"), not a date

CREATE UNIQUE INDEX IF NOT EXISTS idx_documents_pmcid
    ON documents (pmcid) WHERE pmcid IS NOT NULL;
