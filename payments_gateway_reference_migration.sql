-- =====================================================================
-- Insurance Platform — Migration: Payments.gateway_reference
-- Adds the Daraja CheckoutRequestID (STK push) / C2B reference column
-- to Payments and two idempotent resolve procs used by the direct
-- M-Pesa webhook callbacks (MpesaCallbackController):
--   usp_Payment_SetGatewayReference            (STK push accepted -> persist CheckoutRequestID)
--   usp_Payment_ResolveByGatewayReference      (STK callback -> mark SUCCESS/FAILED, flip purchase PAID)
--   usp_Payment_ResolveByTransactionReference  (C2B confirmation -> same, matched on transaction_reference)
-- All procs keep the existing contract: OUT o_result_code 0=Success.
-- =====================================================================

USE insurance_platform;

ALTER TABLE Payments
    ADD COLUMN gateway_reference VARCHAR(100) NULL AFTER transaction_reference,
    ADD INDEX idx_payments_gateway_reference (gateway_reference);

-- The resolve procs audit their webhook calls (actor_type GATEWAY_WEBHOOK);
-- widen the constraint the same way Insurance_API_Schema.sql does.
ALTER TABLE AuditLog DROP CHECK chk_audit_actor_type;
ALTER TABLE AuditLog ADD CONSTRAINT chk_audit_actor_type
    CHECK (actor_type IN ('USER','CLIENT','CHANNEL_SERVICE','GATEWAY_WEBHOOK'));

DELIMITER $$

-- ---------------------------------------------------------------------
-- usp_Payment_SetGatewayReference
-- Called right after a DARAJA_STK push is accepted (from
-- PaymentsController.InitiateStkPush) so the later webhook can find the
-- right Payment by CheckoutRequestID alone, without trusting a client-
-- supplied reference.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_SetGatewayReference $$
CREATE PROCEDURE usp_Payment_SetGatewayReference (
    IN p_payment_id         BIGINT UNSIGNED,
    IN p_gateway_reference  VARCHAR(100),
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500)
)
proc_label: BEGIN
    IF p_payment_id IS NULL OR p_gateway_reference IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'payment_id and gateway_reference are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Payments WHERE payment_id = p_payment_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Payment not found.';
        LEAVE proc_label;
    END IF;

    UPDATE Payments
       SET gateway_reference = p_gateway_reference
     WHERE payment_id = p_payment_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Payment_ResolveByGatewayReference
-- Idempotent resolver for Safaricom STK-push callbacks (the
-- CheckoutRequestID datapoint). Finds the newest PENDING payment carrying
-- that gateway_reference and flips it to SUCCESS/FAILED; on SUCCESS the
-- owning Purchases.payment_status is also set to PAID, on FAILED to
-- FAILED. Already-terminal payments are left untouched (a retried
-- callback returns success with o_not_processed=1 so the API doesn't
-- log it as an error).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_ResolveByGatewayReference $$
-- NOTE: keeps the project's executor convention - o_result_code /
-- o_result_message right after the IN params, proc-specific OUT params
-- (o_payment_id, o_not_processed) last. The executor inserts the two
-- envelope OUTs at the position of the first caller-supplied OUTPUT
-- parameter, so the repository's param order must be INs + o_payment_id +
-- o_not_processed for the positional CALL to line up.
CREATE PROCEDURE usp_Payment_ResolveByGatewayReference (
    IN p_gateway_reference      VARCHAR(100),
    IN p_status                 VARCHAR(20),
    IN p_transaction_reference  VARCHAR(100),
    IN p_actor_type             VARCHAR(20),
    IN p_actor_id               BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_payment_id            BIGINT UNSIGNED,
    OUT o_not_processed         INT
)
proc_label: BEGIN
    DECLARE v_payment_id    BIGINT UNSIGNED;
    DECLARE v_purchase_id   BIGINT UNSIGNED;
    DECLARE v_current_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_gateway_reference IS NULL OR p_status IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'gateway_reference and status are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('SUCCESS','FAILED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be SUCCESS or FAILED.';
        LEAVE proc_label;
    END IF;

    SELECT payment_id, purchase_id, status
      INTO v_payment_id, v_purchase_id, v_current_status
      FROM Payments
     WHERE gateway_reference = p_gateway_reference
     ORDER BY payment_id DESC
     LIMIT 1;

    IF v_payment_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'No payment found for gateway_reference.';
        LEAVE proc_label;
    END IF;

    SET o_payment_id = v_payment_id;
    SET o_not_processed = 1;
    SET o_result_code = 0;
    SET o_result_message = 'Already processed; callback ignored.';

    IF v_current_status NOT IN ('SUCCESS','FAILED') THEN
        START TRANSACTION;

        UPDATE Payments
           SET status = p_status,
               transaction_reference = COALESCE(p_transaction_reference, transaction_reference),
               completed_on = IF(p_status IN ('SUCCESS','FAILED'), NOW(), completed_on)
         WHERE payment_id = v_payment_id;

        IF p_status = 'SUCCESS' THEN
            UPDATE Purchases SET payment_status = 'PAID' WHERE purchase_id = v_purchase_id;
        ELSEIF p_status = 'FAILED' THEN
            UPDATE Purchases SET payment_status = 'FAILED' WHERE purchase_id = v_purchase_id;
        END IF;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES (COALESCE(p_actor_type, 'GATEWAY_WEBHOOK'), COALESCE(p_actor_id, v_purchase_id),
                'STATUS_CHANGE', 'Payments', v_payment_id,
                JSON_OBJECT('status', v_current_status), JSON_OBJECT('status', p_status, 'gateway_reference', p_gateway_reference), NOW());

        SET o_not_processed = 0;
        SET o_result_message = 'Success';

        COMMIT;
    END IF;
END $$

-- ---------------------------------------------------------------------
-- usp_Payment_ResolveByTransactionReference
-- Idempotent resolver for C2B Paybill confirmations, which carry no
-- CheckoutRequestID - matched instead on transaction_reference (the
-- account/BillRefNumber the customer quoted when paying by Paybill).
-- Same semantics as the gateway-reference variant above.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_ResolveByTransactionReference $$
CREATE PROCEDURE usp_Payment_ResolveByTransactionReference (
    IN p_transaction_reference  VARCHAR(100),
    IN p_status                 VARCHAR(20),
    IN p_mpesa_receipt          VARCHAR(100),
    IN p_actor_type             VARCHAR(20),
    IN p_actor_id               BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_payment_id            BIGINT UNSIGNED,
    OUT o_not_processed         INT
)
proc_label: BEGIN
    DECLARE v_payment_id    BIGINT UNSIGNED;
    DECLARE v_purchase_id   BIGINT UNSIGNED;
    DECLARE v_current_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_transaction_reference IS NULL OR p_status IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'transaction_reference and status are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('SUCCESS','FAILED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be SUCCESS or FAILED.';
        LEAVE proc_label;
    END IF;

    SELECT payment_id, purchase_id, status
      INTO v_payment_id, v_purchase_id, v_current_status
      FROM Payments
     WHERE transaction_reference = p_transaction_reference
     ORDER BY payment_id DESC
     LIMIT 1;

    IF v_payment_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'No payment found for transaction_reference.';
        LEAVE proc_label;
    END IF;

    SET o_payment_id = v_payment_id;
    SET o_not_processed = 1;
    SET o_result_code = 0;
    SET o_result_message = 'Already processed; callback ignored.';

    IF v_current_status NOT IN ('SUCCESS','FAILED') THEN
        START TRANSACTION;

        UPDATE Payments
           SET status = p_status,
               transaction_reference = COALESCE(p_mpesa_receipt, transaction_reference),
               completed_on = IF(p_status IN ('SUCCESS','FAILED'), NOW(), completed_on)
         WHERE payment_id = v_payment_id;

        IF p_status = 'SUCCESS' THEN
            UPDATE Purchases SET payment_status = 'PAID' WHERE purchase_id = v_purchase_id;
        ELSEIF p_status = 'FAILED' THEN
            UPDATE Purchases SET payment_status = 'FAILED' WHERE purchase_id = v_purchase_id;
        END IF;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES (COALESCE(p_actor_type, 'GATEWAY_WEBHOOK'), COALESCE(p_actor_id, v_purchase_id),
                'STATUS_CHANGE', 'Payments', v_payment_id,
                JSON_OBJECT('status', v_current_status), JSON_OBJECT('status', p_status, 'transaction_reference', p_transaction_reference), NOW());

        SET o_not_processed = 0;
        SET o_result_message = 'Success';

        COMMIT;
    END IF;
END $$

DELIMITER ;