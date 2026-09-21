-- ============================================================================
-- Offer status transitions + list counts - insurance_platform
--
-- Three objects:
--   1. usp_QuoteOffer_Reject  - marks one ACTIVE offer REJECTED, drops the
--      parent request back to IN_PROGRESS if no ACTIVE offers remain.
--   2. usp_QuoteOffer_Expire  - same shape for EXPIRED.
--   3. usp_QuoteRequest_GetList - recreated to also return offers_count,
--      active_offers_count and rider_count per request (the Quote Requests
--      work-queue badges).
--
-- Recreatable: each proc body is DROP + CREATE, so the file can be re-run.
--
-- Run with:  mysql -u root -p insurance_platform < offer_status_migrations.sql
-- ============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS usp_QuoteOffer_Reject$$
CREATE PROCEDURE usp_QuoteOffer_Reject(
    IN  p_quote_offer_id BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_quote_request_id BIGINT UNSIGNED;
    DECLARE v_remaining_active INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error - transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_offer_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT quote_request_id INTO v_quote_request_id
    FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_quote_request_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active quote offer not found (it may have already been selected, rejected, expired, or deleted).';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteOffers
    SET status = 'REJECTED'
    WHERE quote_offer_id = p_quote_offer_id;

    SELECT COUNT(*) INTO v_remaining_active
    FROM QuoteOffers
    WHERE quote_request_id = v_quote_request_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_remaining_active = 0 THEN
        UPDATE QuoteRequests SET status = 'IN_PROGRESS' WHERE quote_request_id = v_quote_request_id AND status = 'QUOTED';
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'REJECT', 'QuoteOffers', p_quote_offer_id, JSON_OBJECT('status', 'ACTIVE'), JSON_OBJECT('status', 'REJECTED'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$

DROP PROCEDURE IF EXISTS usp_QuoteOffer_Expire$$
CREATE PROCEDURE usp_QuoteOffer_Expire(
    IN  p_quote_offer_id BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_quote_request_id BIGINT UNSIGNED;
    DECLARE v_remaining_active INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error - transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_offer_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT quote_request_id INTO v_quote_request_id
    FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_quote_request_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active quote offer not found (it may have already been selected, rejected, expired, or deleted).';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteOffers
    SET status = 'EXPIRED'
    WHERE quote_offer_id = p_quote_offer_id;

    SELECT COUNT(*) INTO v_remaining_active
    FROM QuoteOffers
    WHERE quote_request_id = v_quote_request_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_remaining_active = 0 THEN
        UPDATE QuoteRequests SET status = 'IN_PROGRESS' WHERE quote_request_id = v_quote_request_id AND status = 'QUOTED';
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'EXPIRE', 'QuoteOffers', p_quote_offer_id, JSON_OBJECT('status', 'ACTIVE'), JSON_OBJECT('status', 'EXPIRED'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$

DROP PROCEDURE IF EXISTS usp_QuoteRequest_GetList$$
CREATE PROCEDURE usp_QuoteRequest_GetList(
    IN  p_status                       VARCHAR(20),
    IN  p_assigned_backoffice_user_id  BIGINT UNSIGNED,
    IN  p_product_id                   BIGINT UNSIGNED,
    IN  p_page_number                  INT,
    IN  p_page_size                    INT,
    OUT o_result_code                  INT,
    OUT o_result_message               VARCHAR(500),
    OUT o_total_count                  BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM QuoteRequests qr
    WHERE (p_status IS NULL OR qr.status = p_status)
      AND (p_assigned_backoffice_user_id IS NULL OR qr.assigned_backoffice_user_id = p_assigned_backoffice_user_id)
      AND (p_product_id IS NULL OR qr.product_id = p_product_id);

    SELECT qr.quote_request_id, qr.ref_no, qr.product_id, p.code AS product_code, qr.client_id,
           qr.requested_by_user_id, qr.channel, qr.status, qr.assigned_backoffice_user_id, qr.created_on,
           (SELECT COUNT(*) FROM QuoteOffers qo
             WHERE qo.quote_request_id = qr.quote_request_id AND qo.isdeleted = 0) AS offers_count,
           (SELECT COUNT(*) FROM QuoteOffers qo
             WHERE qo.quote_request_id = qr.quote_request_id AND qo.isdeleted = 0 AND qo.status = 'ACTIVE') AS active_offers_count,
           (SELECT COUNT(*) FROM QuoteOfferRiders r
             JOIN QuoteOffers qo ON qo.quote_offer_id = r.quote_offer_id
             WHERE qo.quote_request_id = qr.quote_request_id AND qo.isdeleted = 0 AND r.isdeleted = 0) AS rider_count
    FROM QuoteRequests qr
    JOIN Products p ON p.product_id = qr.product_id
    WHERE (p_status IS NULL OR qr.status = p_status)
      AND (p_assigned_backoffice_user_id IS NULL OR qr.assigned_backoffice_user_id = p_assigned_backoffice_user_id)
      AND (p_product_id IS NULL OR qr.product_id = p_product_id)
    ORDER BY FIELD(qr.status, 'PENDING', 'IN_PROGRESS', 'QUOTED', 'EXPIRED', 'CONVERTED'), qr.created_on ASC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$

DELIMITER ;