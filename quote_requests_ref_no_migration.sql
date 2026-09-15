-- =====================================================================
-- Migration: add ref_no (short external tracking code) to QuoteRequests
-- ---------------------------------------------------------------------
-- Run this once against an already-existing database (a fresh install
-- picks this up automatically from Insurance_API_Schema.sql instead).
-- Also re-run Insurance_API_StoredProcs_Quotes.sql after this - the five
-- usp_QuoteRequest<Type>_Create procs, usp_QuoteRequest_GetById and
-- usp_QuoteRequest_GetList all changed to generate/return ref_no, and
-- your database won't have those changes until that file is re-applied.
-- =====================================================================

USE insurance_platform;

ALTER TABLE QuoteRequests
    ADD COLUMN ref_no VARCHAR(20) NULL AFTER quote_request_id;

-- Backfill every existing row with a generated ref_no, prefixed by its
-- product code the same way the Create procs prefix new ones from now on
-- (MI/MC/PI/TR/DM). Collision odds at 6 hex characters (16.7M
-- combinations) are effectively zero for any realistic existing row
-- count - if the UNIQUE constraint below still fails with a duplicate
-- error, just re-run this UPDATE once more before retrying the ALTER.
UPDATE QuoteRequests qr
JOIN Products p ON p.product_id = qr.product_id
SET qr.ref_no = CONCAT(
    CASE p.code
        WHEN 'MED_IND'  THEN 'MI'
        WHEN 'MED_CORP' THEN 'MC'
        WHEN 'PI'       THEN 'PI'
        WHEN 'TRAVEL'   THEN 'TR'
        WHEN 'DOMESTIC' THEN 'DM'
        ELSE 'QR'
    END,
    '-', UPPER(SUBSTRING(MD5(RAND()), 1, 6))
)
WHERE qr.ref_no IS NULL;

ALTER TABLE QuoteRequests
    ADD CONSTRAINT uq_qr_ref_no UNIQUE (ref_no);
