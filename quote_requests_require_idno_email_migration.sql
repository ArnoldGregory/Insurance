-- =====================================================================
-- Migration: require id_no + email on every quote request type
-- ---------------------------------------------------------------------
-- Run this once against an already-existing database (a fresh install
-- picks this up automatically from Insurance_API_Schema.sql instead).
-- Also re-run Insurance_API_StoredProcs_Quotes.sql after this - all 5
-- usp_QuoteRequest<Type>_Create procs changed to accept/require id_no and
-- email.
--
-- What changes, per type:
--   Medical Individual   - already had id_no (NOT NULL) and email
--                           (NULL-able) - email flips to NOT NULL.
--   Medical Corporate    - already had email (NOT NULL) - id_no is a new
--                           column (the requester's own ID, not a company
--                           registration number).
--   Professional Indemnity - same as Medical Corporate: id_no is new,
--                           email was already required.
--   Travel                - both id_no and email are new columns (Travel
--                           only had kra_pin before, which is optional
--                           and not the same thing).
--   Domestic               - both id_no and email are new columns, pulled
--                           out ahead of the rest of Domestic's still-
--                           unconfirmed field list (details_json stays as
--                           a placeholder for everything else).
--
-- Backfill strategy: existing rows can't have a real id_no/email invented
-- for them, so they're backfilled with an obvious placeholder value
-- ('UNKNOWN' / 'unknown+qr<id>@placeholder.local') before the NOT NULL
-- constraint is applied - review/replace these manually for any request
-- that's still active (PENDING/IN_PROGRESS/QUOTED) and actually needs a
-- real email to receive the client-received/offers-comparison emails
-- this migration's feature depends on.
-- =====================================================================

USE insurance_platform;

-- ---- Medical Individual: email NULL -> NOT NULL ----
UPDATE QuoteRequestMedicalIndividual
SET email = CONCAT('unknown+qr', quote_request_id, '@placeholder.local')
WHERE email IS NULL;

ALTER TABLE QuoteRequestMedicalIndividual
    MODIFY COLUMN email VARCHAR(150) NOT NULL;

-- ---- Medical Corporate: add id_no ----
ALTER TABLE QuoteRequestMedicalCorporate
    ADD COLUMN id_no VARCHAR(50) NULL AFTER quote_request_id;

UPDATE QuoteRequestMedicalCorporate SET id_no = 'UNKNOWN' WHERE id_no IS NULL;

ALTER TABLE QuoteRequestMedicalCorporate
    MODIFY COLUMN id_no VARCHAR(50) NOT NULL;

-- ---- Professional Indemnity: add id_no ----
ALTER TABLE QuoteRequestProfessionalIndemnity
    ADD COLUMN id_no VARCHAR(50) NULL AFTER quote_request_id;

UPDATE QuoteRequestProfessionalIndemnity SET id_no = 'UNKNOWN' WHERE id_no IS NULL;

ALTER TABLE QuoteRequestProfessionalIndemnity
    MODIFY COLUMN id_no VARCHAR(50) NOT NULL;

-- ---- Travel: add id_no + email ----
ALTER TABLE QuoteRequestTravel
    ADD COLUMN id_no VARCHAR(50) NULL AFTER quote_request_id,
    ADD COLUMN email VARCHAR(150) NULL AFTER id_no;

UPDATE QuoteRequestTravel SET id_no = 'UNKNOWN' WHERE id_no IS NULL;
UPDATE QuoteRequestTravel
SET email = CONCAT('unknown+qr', quote_request_id, '@placeholder.local')
WHERE email IS NULL;

ALTER TABLE QuoteRequestTravel
    MODIFY COLUMN id_no VARCHAR(50) NOT NULL,
    MODIFY COLUMN email VARCHAR(150) NOT NULL;

-- ---- Domestic: add id_no + email ----
ALTER TABLE QuoteRequestDomestic
    ADD COLUMN id_no VARCHAR(50) NULL AFTER quote_request_id,
    ADD COLUMN email VARCHAR(150) NULL AFTER id_no;

UPDATE QuoteRequestDomestic SET id_no = 'UNKNOWN' WHERE id_no IS NULL;
UPDATE QuoteRequestDomestic
SET email = CONCAT('unknown+qr', quote_request_id, '@placeholder.local')
WHERE email IS NULL;

ALTER TABLE QuoteRequestDomestic
    MODIFY COLUMN id_no VARCHAR(50) NOT NULL,
    MODIFY COLUMN email VARCHAR(150) NOT NULL;

-- ---------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------
SELECT 'QuoteRequestMedicalIndividual' AS table_name, COUNT(*) AS placeholder_email_rows
FROM QuoteRequestMedicalIndividual WHERE email LIKE 'unknown+qr%'
UNION ALL
SELECT 'QuoteRequestMedicalCorporate', COUNT(*) FROM QuoteRequestMedicalCorporate WHERE id_no = 'UNKNOWN'
UNION ALL
SELECT 'QuoteRequestProfessionalIndemnity', COUNT(*) FROM QuoteRequestProfessionalIndemnity WHERE id_no = 'UNKNOWN'
UNION ALL
SELECT 'QuoteRequestTravel (id_no)', COUNT(*) FROM QuoteRequestTravel WHERE id_no = 'UNKNOWN'
UNION ALL
SELECT 'QuoteRequestTravel (email)', COUNT(*) FROM QuoteRequestTravel WHERE email LIKE 'unknown+qr%'
UNION ALL
SELECT 'QuoteRequestDomestic (id_no)', COUNT(*) FROM QuoteRequestDomestic WHERE id_no = 'UNKNOWN'
UNION ALL
SELECT 'QuoteRequestDomestic (email)', COUNT(*) FROM QuoteRequestDomestic WHERE email LIKE 'unknown+qr%';
