-- ============================================================================
-- Server (insurance_platform @ 167.86.125.237) setup
-- Target database: insurance_platform
--
-- Two parts:
--   1. `parameter` config table (schema + rows) taken from the local
--      insurance_platform database. Safe/idempotent: CREATE TABLE IF NOT
--      EXISTS and INSERT ... ON DUPLICATE KEY UPDATE - existing rows with the
--      same id are updated, nothing is dropped.
--   2. Offer add-ons objects: QuoteOfferRiders table + the two stored
--      procedures used by the add-ons screen.
--
-- Run with:  mysql -u esbuser -p insurance_platform < server_setup_migration.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) parameter
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `parameter` (
  `id` int NOT NULL AUTO_INCREMENT,
  `item_key` varchar(50) DEFAULT NULL,
  `item_value` varchar(2000) DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `created_on` datetime DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  `approved` tinyint(1) DEFAULT NULL,
  `approved_on` datetime DEFAULT NULL,
  `approved_by` int DEFAULT NULL,
  `is_deleted` smallint DEFAULT NULL,
  `deleted_on` datetime DEFAULT NULL,
  `deleted_by` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4;

INSERT INTO `parameter` (`id`, `item_key`, `item_value`, `comments`, `created_on`, `created_by`, `approved`, `approved_on`, `approved_by`, `is_deleted`, `deleted_on`, `deleted_by`) VALUES
(1,'business_short_code','4137235','Business Paybill Number','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(2,'SCAPI_STK_API','https://riziki.app:9000/api/MobileMoney/SubmitRequest','STK Push Gateway Endpoint','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(3,'SCAPI_STK_USER','c21hcnRjb2Rl','STK Gateway Basic Auth User','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(4,'SCAPI_STK_PASSWORD','MTIzNDU2','STK Gateway Basic Auth Password','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(5,'MPESA_CALLBACK','https://your-new-domain.com/api/PochiSolid/SubmitRequest','New Project MPESA Callback','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(6,'RIZIKI_B2C_TIMEOUT_URL','https://your-new-domain.com/Invoice/TimeoutRequest','B2C Timeout Endpoint','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL),
(7,'RIZIKI_B2C_RESULT_URL','https://your-new-domain.com/Invoice/MpesaB2CResultUrl','B2C Result Endpoint','2026-09-16 12:43:58',1,1,'2026-09-16 12:43:58',1,NULL,NULL,NULL)
ON DUPLICATE KEY UPDATE
  item_key = VALUES(item_key),
  item_value = VALUES(item_value),
  comments = VALUES(comments);

-- ----------------------------------------------------------------------------
-- 2) Offer add-ons
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS QuoteOfferRiders (
    rider_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    quote_offer_id  BIGINT UNSIGNED NOT NULL,
    name            VARCHAR(150)    NOT NULL,
    amount          DECIMAL(18,2)   NULL,
    note            VARCHAR(500)    NULL,
    created_on      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    isdeleted       TINYINT(1)      NOT NULL DEFAULT 0,
    deleted_by      BIGINT UNSIGNED NULL,
    deleted_on      DATETIME        NULL,
    PRIMARY KEY (rider_id),
    KEY idx_qor_offer (quote_offer_id),
    CONSTRAINT fk_qor_offer FOREIGN KEY (quote_offer_id)
        REFERENCES QuoteOffers (quote_offer_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- 2a) usp_QuoteOfferRider_Replace
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOfferRider_Replace;
DELIMITER $$

CREATE PROCEDURE usp_QuoteOfferRider_Replace(
    IN  p_quote_offer_id BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,
    IN  p_addons_json    TEXT,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old_count INT DEFAULT 0;
    DECLARE v_new_count INT DEFAULT 0;

    IF p_quote_offer_id IS NULL OR p_actor_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id and actor_id are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Offer not found.';
        LEAVE proc_label;
    END IF;

    SELECT COUNT(*) INTO v_old_count
      FROM QuoteOfferRiders
     WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0;

    UPDATE QuoteOfferRiders
       SET isdeleted = 1, deleted_by = p_actor_id, deleted_on = NOW()
     WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0;

    IF p_addons_json IS NULL OR TRIM(p_addons_json) = '' OR TRIM(p_addons_json) = '[]' THEN
        SET v_new_count = 0;
    ELSE
        INSERT INTO QuoteOfferRiders (quote_offer_id, name, amount, note)
        SELECT p_quote_offer_id, jt.name, jt.amount, jt.note
          FROM JSON_TABLE(p_addons_json, '$[*]' COLUMNS (
                    name   VARCHAR(150)  PATH '$.name',
                    amount DECIMAL(18,2) PATH '$.amount',
                    note   VARCHAR(500)  PATH '$.note'
               )) AS jt
         WHERE jt.name IS NOT NULL AND TRIM(jt.name) <> '';
        SET v_new_count = ROW_COUNT();
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'REPLACE', 'QuoteOfferRiders', p_quote_offer_id,
            JSON_OBJECT('removed', v_old_count), JSON_OBJECT('added', v_new_count), NOW());

    SET o_result_code = 0;
    SET o_result_message = CONCAT('Add-ons updated (', v_new_count, ').');
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 2b) usp_QuoteOfferRider_GetByOffer
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOfferRider_GetByOffer;
DELIMITER $$

CREATE PROCEDURE usp_QuoteOfferRider_GetByOffer(
    IN  p_quote_offer_id BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_quote_offer_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Offer not found.';
        LEAVE proc_label;
    END IF;

    SELECT rider_id, quote_offer_id, name, amount, note, created_on
      FROM QuoteOfferRiders
     WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0
     ORDER BY rider_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$

DELIMITER ;

-- ============================================================================
-- Done. Add-ons feature + parameter config are ready on the server DB.
-- ============================================================================