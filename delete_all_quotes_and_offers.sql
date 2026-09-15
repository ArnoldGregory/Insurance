-- =====================================================================
-- Delete: every Quote Request, cascading to every detail row and every
-- Quote Offer.
-- -----------------------------------------------------------------------
-- What gets removed and why, table by table:
--
--   QuoteOffers                        - deleted explicitly, FIRST. Its FK
--                                         (fk_qo_request) is ON DELETE
--                                         RESTRICT, not CASCADE, so
--                                         QuoteRequests rows that still
--                                         have offers can't be deleted
--                                         until this runs.
--   QuoteRequestMedicalIndividual       - all ON DELETE CASCADE against
--   QuoteRequestMedicalCorporate          QuoteRequests, so deleting
--   QuoteRequestProfessionalIndemnity     QuoteRequests below removes
--   QuoteRequestTravel                    these automatically. Nothing to
--   QuoteRequestDomestic                  do by hand for these five.
--   QuoteRequests                       - deleted second (and last),
--                                         which is what actually cascades
--                                         the five detail tables above.
--
-- Left alone on purpose:
--   Purchases.quote_offer_id  - FK is ON DELETE SET NULL, not RESTRICT,
--                                so any Purchase that pointed at a deleted
--                                offer just has that column cleared to
--                                NULL automatically - the Purchase row
--                                itself is NOT deleted, and this script
--                                does not touch the Purchases table.
--   AuditLog                  - a polymorphic history table (entity +
--                                entity_id columns, no real FK to
--                                QuoteRequests/QuoteOffers) - existing
--                                CREATE/ASSIGN/STATUS_CHANGE log rows for
--                                deleted quotes are left in place
--                                intentionally, same as every other
--                                soft-delete/hard-delete in this codebase
--                                never touches its own audit trail.
--   Uploaded offer documents  - QuoteOffers.document_path only stores a
--                                path/URL string; the actual uploaded
--                                files on disk (or blob storage) are NOT
--                                deleted by this script - SQL can't reach
--                                the filesystem. The SELECT right before
--                                the DELETE below prints every path that's
--                                about to become orphaned, so you can
--                                clean those files up by hand if you want
--                                to reclaim that disk space too.
--
-- This is a hard, irreversible DELETE (no isdeleted/soft-delete flag on
-- QuoteRequests) - there is no "undo" once this runs. Take a backup first
-- if there's any chance you'll want this data back.
-- =====================================================================

USE insurance_platform;

-- ---------------------------------------------------------------------
-- Preview - review these before running the DELETEs below.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS quote_requests_about_to_be_deleted FROM QuoteRequests;
SELECT COUNT(*) AS quote_offers_about_to_be_deleted FROM QuoteOffers;

-- Every uploaded offer document path that's about to be orphaned on disk -
-- copy this list out before running the DELETE if you want to clean the
-- actual files up afterwards.
SELECT quote_offer_id, quote_request_id, document_path
FROM QuoteOffers
WHERE document_path IS NOT NULL;

-- ---------------------------------------------------------------------
-- The actual deletes - order matters (see comment above: QuoteOffers'
-- FK to QuoteRequests is RESTRICT, so it must go first).
-- ---------------------------------------------------------------------
DELETE FROM QuoteOffers;
DELETE FROM QuoteRequests;

-- Optional - uncomment both lines below if you also want the next quote
-- request / quote offer created after this to start back at id 1 (handy
-- for a clean demo/test reset; leave commented if other systems already
-- reference the current id sequence and you don't want a gap/reset).
-- ALTER TABLE QuoteRequests AUTO_INCREMENT = 1;
-- ALTER TABLE QuoteOffers AUTO_INCREMENT = 1;

-- ---------------------------------------------------------------------
-- Verification - both should read 0, and every detail table should be
-- empty too (proves the CASCADE actually fired).
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS quote_requests_remaining FROM QuoteRequests;
SELECT COUNT(*) AS quote_offers_remaining FROM QuoteOffers;
SELECT COUNT(*) AS medical_individual_remaining FROM QuoteRequestMedicalIndividual;
SELECT COUNT(*) AS medical_corporate_remaining FROM QuoteRequestMedicalCorporate;
SELECT COUNT(*) AS professional_indemnity_remaining FROM QuoteRequestProfessionalIndemnity;
SELECT COUNT(*) AS travel_remaining FROM QuoteRequestTravel;
SELECT COUNT(*) AS domestic_remaining FROM QuoteRequestDomestic;
