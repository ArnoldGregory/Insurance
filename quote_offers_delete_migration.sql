-- =====================================================================
-- Migration: add soft-delete columns to QuoteOffers
-- ---------------------------------------------------------------------
-- Run this once against an already-existing database (a fresh install
-- picks this up automatically from Insurance_API_Schema.sql instead).
-- Needed for the new "delete an offer" feature on the Quote Requests
-- back-office screen - matches the same isdeleted/deleted_by/deleted_on
-- convention already used on Users/Clients/Vehicles, just extended to
-- QuoteOffers, which didn't need it until now.
-- =====================================================================

USE insurance_platform;

ALTER TABLE QuoteOffers
    ADD COLUMN isdeleted  TINYINT(1) NOT NULL DEFAULT 0 AFTER status,
    ADD COLUMN deleted_by BIGINT UNSIGNED NULL           AFTER isdeleted,
    ADD COLUMN deleted_on DATETIME NULL                  AFTER deleted_by,
    ADD CONSTRAINT fk_qo_deleted_by FOREIGN KEY (deleted_by) REFERENCES Users(user_id) ON DELETE RESTRICT;
