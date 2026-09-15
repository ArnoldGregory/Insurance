-- =====================================================================
-- Insurance Platform — Stored Procedures: COMMISSIONS (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Covers: AgentCommissionRates (one flat % per agent - NOT per product or
-- underwriter; commission belongs to the agent, applies to everything they
-- sell), manual/backfill accrual, and the withdrawal request/approve/pay/
-- reject flow.
-- NOTE: usp_Purchase_Create already accrues commission inline at purchase
-- time using the same single-lookup resolution duplicated here —
-- usp_AgentCommission_Accrue below is for the backfill case (a purchase
-- happened before the agent had a rate assigned yet).
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- =====================================================================
-- AGENT COMMISSION RATES (one flat % per agent)
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_AgentCommissionRate_Set
-- Insert-only history pattern: closes the agent's currently active rate,
-- inserts the new one. No product_id/underwriter_id - this rate applies
-- to every purchase the agent executes, regardless of what they sell or
-- through which underwriter.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommissionRate_Set $$
CREATE PROCEDURE usp_AgentCommissionRate_Set (
    IN  p_agent_user_id  BIGINT UNSIGNED,
    IN  p_rate_percent   DECIMAL(5,2),
    IN  p_effective_from DATE,
    IN  p_set_by_user_id BIGINT UNSIGNED,   -- Agent_admin
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_rate_id        BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_old_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_agent_user_id IS NULL OR p_rate_percent IS NULL OR p_set_by_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id, rate_percent and set_by_user_id are required.';
        LEAVE proc_label;
    END IF;

    IF p_rate_percent <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'rate_percent must be greater than zero.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_agent_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Agent not found.';
        LEAVE proc_label;
    END IF;

    IF p_effective_from IS NULL THEN
        SET p_effective_from = CURDATE();
    END IF;

    START TRANSACTION;

    SELECT rate_id INTO v_old_id
    FROM AgentCommissionRates
    WHERE agent_user_id = p_agent_user_id
      AND (effective_to IS NULL OR effective_to >= CURDATE())
    ORDER BY effective_from DESC
    LIMIT 1
    FOR UPDATE;

    IF v_old_id IS NOT NULL THEN
        UPDATE AgentCommissionRates
        SET effective_to = DATE_SUB(p_effective_from, INTERVAL 1 DAY)
        WHERE rate_id = v_old_id;
    END IF;

    INSERT INTO AgentCommissionRates (agent_user_id, rate_percent, effective_from, effective_to, set_by_user_id, created_on)
    VALUES (p_agent_user_id, p_rate_percent, p_effective_from, NULL, p_set_by_user_id, NOW());

    SET o_rate_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_set_by_user_id, 'CREATE', 'AgentCommissionRates', o_rate_id,
            IF(v_old_id IS NOT NULL, JSON_OBJECT('superseded_rate_id', v_old_id), NULL),
            JSON_OBJECT('agent_user_id', p_agent_user_id, 'rate_percent', p_rate_percent,
                        'effective_from', p_effective_from),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_AgentCommissionRate_GetListByAgent
-- Full history (current + superseded rows) - not just the active one -
-- same reasoning as every other insert-only-history list in this project
-- (TpoPriceMapping, ComprehensiveRateFormula): "what was this agent's rate
-- on date X" should always be answerable.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommissionRate_GetListByAgent $$
CREATE PROCEDURE usp_AgentCommissionRate_GetListByAgent (
    IN  p_agent_user_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT rate_id, agent_user_id, rate_percent, effective_from, effective_to, set_by_user_id, created_on
    FROM AgentCommissionRates
    WHERE agent_user_id = p_agent_user_id
    ORDER BY effective_from DESC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- AGENT COMMISSIONS (per-purchase earnings)
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_AgentCommission_Accrue
-- Manual/backfill accrual for a purchase that didn't get one automatically
-- (e.g. the agent didn't have a rate configured yet at purchase time).
-- Resolves the rate the same way usp_Purchase_Create does: the agent's
-- single active flat rate, applied to the purchase's premium amount.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommission_Accrue $$
CREATE PROCEDURE usp_AgentCommission_Accrue (
    IN  p_purchase_id    BIGINT UNSIGNED,
    IN  p_agent_user_id  BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,   -- Agent_admin performing the backfill
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_commission_id  BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_premium_amount DECIMAL(18,2);
    DECLARE v_rate_percent DECIMAL(5,2);
    DECLARE v_commission_amount DECIMAL(18,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_purchase_id IS NULL OR p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id and agent_user_id are required.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM AgentCommissions WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 3;
        SET o_result_message = 'This purchase already has a commission record.';
        LEAVE proc_label;
    END IF;

    SELECT premium_amount INTO v_premium_amount
    FROM Purchases WHERE purchase_id = p_purchase_id;

    IF v_premium_amount IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    -- Commission belongs to the agent alone - one flat rate applied to
    -- every purchase they make, regardless of product or underwriter.
    SELECT rate_percent INTO v_rate_percent
    FROM AgentCommissionRates
    WHERE agent_user_id = p_agent_user_id
      AND effective_from <= CURDATE()
      AND (effective_to IS NULL OR effective_to >= CURDATE())
    ORDER BY effective_from DESC
    LIMIT 1;

    IF v_rate_percent IS NULL THEN
        SET o_result_code = 4;
        SET o_result_message = 'No commission rate is configured for this agent yet.';
        LEAVE proc_label;
    END IF;

    SET v_commission_amount = v_premium_amount * v_rate_percent / 100;

    START TRANSACTION;

    INSERT INTO AgentCommissions (purchase_id, agent_user_id, rate_percent_applied, cover_amount,
                                   commission_amount, status, created_on)
    VALUES (p_purchase_id, p_agent_user_id, v_rate_percent, v_premium_amount,
            v_commission_amount, 'ACCRUED', NOW());

    SET o_commission_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'AgentCommissions', o_commission_id,
            NULL, JSON_OBJECT('purchase_id', p_purchase_id, 'agent_user_id', p_agent_user_id,
                              'rate_percent_applied', v_rate_percent, 'commission_amount', v_commission_amount),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_AgentCommission_GetListByAgent
-- Paginated earnings ledger for an agent's own view.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommission_GetListByAgent $$
CREATE PROCEDURE usp_AgentCommission_GetListByAgent (
    IN  p_agent_user_id BIGINT UNSIGNED,
    IN  p_status        VARCHAR(20),   -- ACCRUED / WITHDRAWN / NULL for all
    IN  p_page_number   INT,
    IN  p_page_size     INT,
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500),
    OUT o_total_count   BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM AgentCommissions ac
    WHERE ac.agent_user_id = p_agent_user_id
      AND (p_status IS NULL OR ac.status = p_status);

    SELECT ac.commission_id, ac.purchase_id, pu.policy_number, ac.rate_percent_applied,
           ac.cover_amount, ac.commission_amount, ac.status, ac.withdrawal_id, ac.created_on
    FROM AgentCommissions ac
    JOIN Purchases pu ON pu.purchase_id = ac.purchase_id
    WHERE ac.agent_user_id = p_agent_user_id
      AND (p_status IS NULL OR ac.status = p_status)
    ORDER BY ac.created_on DESC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_AgentCommission_GetAvailableBalance
-- Sum of ACCRUED commissions not yet reserved by a pending/paid
-- withdrawal — this is what the agent can currently request.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommission_GetAvailableBalance $$
CREATE PROCEDURE usp_AgentCommission_GetAvailableBalance (
    IN  p_agent_user_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500),
    OUT o_available_balance DECIMAL(18,2)
)
proc_label: BEGIN
    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT COALESCE(SUM(commission_amount), 0) INTO o_available_balance
    FROM AgentCommissions
    WHERE agent_user_id = p_agent_user_id
      AND status = 'ACCRUED'
      AND withdrawal_id IS NULL;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_AgentCommission_GetSummary
-- Platform-wide rollup for the SuperAdmin/AgentAdmin/SupportAgent
-- dashboards - "how much commission is moving through the whole agent
-- network", not any one agent's own numbers (that's
-- usp_AgentCommission_GetAvailableBalance, unchanged, still per-agent).
-- total_accrued/total_withdrawn are all-time sums by AgentCommissions.status;
-- available_balance mirrors GetAvailableBalance's own WHERE clause but
-- without the per-agent filter (every ACCRUED row not yet claimed by a
-- withdrawal); pending_withdrawal_count/amount is the same REQUESTED/
-- APPROVED queue usp_CommissionWithdrawal_GetPendingList lists in full,
-- just counted here as one stat-card number. Each column below is a plain
-- (non-correlated) scalar subquery - there's no outer row to correlate to,
-- this is just five independent one-number queries packaged into one row.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_AgentCommission_GetSummary $$
CREATE PROCEDURE usp_AgentCommission_GetSummary (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT
        COALESCE((SELECT SUM(commission_amount) FROM AgentCommissions WHERE status = 'ACCRUED'), 0)
            AS total_accrued,
        COALESCE((SELECT SUM(commission_amount) FROM AgentCommissions WHERE status = 'WITHDRAWN'), 0)
            AS total_withdrawn,
        COALESCE((SELECT SUM(commission_amount) FROM AgentCommissions WHERE status = 'ACCRUED' AND withdrawal_id IS NULL), 0)
            AS available_balance,
        COALESCE((SELECT COUNT(*) FROM CommissionWithdrawals WHERE status IN ('REQUESTED','APPROVED')), 0)
            AS pending_withdrawal_count,
        COALESCE((SELECT SUM(amount) FROM CommissionWithdrawals WHERE status IN ('REQUESTED','APPROVED')), 0)
            AS pending_withdrawal_amount;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- COMMISSION WITHDRAWALS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_CommissionWithdrawal_Request
-- Withdraws the agent's full available balance (ACCRUED commissions not
-- already reserved by another pending/paid withdrawal) — no partial-amount
-- withdrawals in this version, which keeps the row-level reservation
-- below unambiguous. The qualifying AgentCommissions rows are reserved
-- immediately (withdrawal_id set) so they can't be double-claimed by a
-- second request before this one resolves; status stays ACCRUED until
-- actually PAID, and REJECTED releases the reservation.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_CommissionWithdrawal_Request $$
CREATE PROCEDURE usp_CommissionWithdrawal_Request (
    IN  p_agent_user_id  BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_withdrawal_id  BIGINT UNSIGNED,
    OUT o_amount         DECIMAL(18,2)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    SELECT COALESCE(SUM(commission_amount), 0) INTO o_amount
    FROM AgentCommissions
    WHERE agent_user_id = p_agent_user_id AND status = 'ACCRUED' AND withdrawal_id IS NULL
    FOR UPDATE;

    IF o_amount IS NULL OR o_amount <= 0 THEN
        ROLLBACK;
        SET o_result_code = 4;
        SET o_result_message = 'No available commission balance to withdraw.';
        LEAVE proc_label;
    END IF;

    INSERT INTO CommissionWithdrawals (agent_user_id, amount, status, requested_on)
    VALUES (p_agent_user_id, o_amount, 'REQUESTED', NOW());

    SET o_withdrawal_id = LAST_INSERT_ID();

    UPDATE AgentCommissions
    SET withdrawal_id = o_withdrawal_id
    WHERE agent_user_id = p_agent_user_id AND status = 'ACCRUED' AND withdrawal_id IS NULL;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_agent_user_id, 'CREATE', 'CommissionWithdrawals', o_withdrawal_id,
            NULL, JSON_OBJECT('agent_user_id', p_agent_user_id, 'amount', o_amount), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_CommissionWithdrawal_UpdateStatus
-- APPROVED: just a status marker, no row changes.
-- PAID: flips the reserved AgentCommissions rows to WITHDRAWN.
-- REJECTED: releases the reservation (withdrawal_id -> NULL), rows stay
--           ACCRUED and become available for a future withdrawal request.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_CommissionWithdrawal_UpdateStatus $$
CREATE PROCEDURE usp_CommissionWithdrawal_UpdateStatus (
    IN  p_withdrawal_id  BIGINT UNSIGNED,
    IN  p_status         VARCHAR(20),   -- APPROVED / PAID / REJECTED
    IN  p_actor_id       BIGINT UNSIGNED,   -- Agent_admin/Support processing it
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_withdrawal_id IS NULL OR p_status IS NULL OR p_actor_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'withdrawal_id, status and actor_id are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('APPROVED','PAID','REJECTED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be APPROVED, PAID or REJECTED.';
        LEAVE proc_label;
    END IF;

    SELECT status INTO v_old_status FROM CommissionWithdrawals WHERE withdrawal_id = p_withdrawal_id;

    IF v_old_status IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Withdrawal request not found.';
        LEAVE proc_label;
    END IF;

    IF v_old_status IN ('PAID','REJECTED') THEN
        SET o_result_code = 4;
        SET o_result_message = 'This withdrawal has already been finalized.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE CommissionWithdrawals
    SET status = p_status, processed_by_user_id = p_actor_id, processed_on = NOW()
    WHERE withdrawal_id = p_withdrawal_id;

    IF p_status = 'PAID' THEN
        UPDATE AgentCommissions SET status = 'WITHDRAWN' WHERE withdrawal_id = p_withdrawal_id;
    ELSEIF p_status = 'REJECTED' THEN
        UPDATE AgentCommissions SET withdrawal_id = NULL WHERE withdrawal_id = p_withdrawal_id;
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'STATUS_CHANGE', 'CommissionWithdrawals', p_withdrawal_id,
            JSON_OBJECT('status', v_old_status), JSON_OBJECT('status', p_status), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_CommissionWithdrawal_GetListByAgent
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_CommissionWithdrawal_GetListByAgent $$
CREATE PROCEDURE usp_CommissionWithdrawal_GetListByAgent (
    IN  p_agent_user_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT withdrawal_id, agent_user_id, amount, status, requested_on, processed_by_user_id, processed_on
    FROM CommissionWithdrawals
    WHERE agent_user_id = p_agent_user_id
    ORDER BY requested_on DESC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_CommissionWithdrawal_GetPendingList
-- Queue for Agent_admin/Support to process outstanding requests.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_CommissionWithdrawal_GetPendingList $$
CREATE PROCEDURE usp_CommissionWithdrawal_GetPendingList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT cw.withdrawal_id, cw.agent_user_id, u.full_name AS agent_name, cw.amount,
           cw.status, cw.requested_on
    FROM CommissionWithdrawals cw
    JOIN Users u ON u.user_id = cw.agent_user_id
    WHERE cw.status IN ('REQUESTED','APPROVED')
    ORDER BY cw.requested_on ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- =====================================================================
-- AUDIT LOG (system-wide — not specific to Commissions, placed here as
-- the last module written; used by compliance/admin review screens)
-- =====================================================================

DROP PROCEDURE IF EXISTS usp_AuditLog_GetList $$
CREATE PROCEDURE usp_AuditLog_GetList (
    IN  p_entity        VARCHAR(100),
    IN  p_entity_id     BIGINT UNSIGNED,
    IN  p_actor_type    VARCHAR(20),
    IN  p_actor_id      BIGINT UNSIGNED,
    IN  p_date_from     DATE,
    IN  p_date_to       DATE,
    IN  p_page_number   INT,
    IN  p_page_size     INT,
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500),
    OUT o_total_count   BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 50; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM AuditLog a
    WHERE (p_entity IS NULL OR a.entity = p_entity)
      AND (p_entity_id IS NULL OR a.entity_id = p_entity_id)
      AND (p_actor_type IS NULL OR a.actor_type = p_actor_type)
      AND (p_actor_id IS NULL OR a.actor_id = p_actor_id)
      AND (p_date_from IS NULL OR a.created_on >= p_date_from)
      AND (p_date_to IS NULL OR a.created_on < DATE_ADD(p_date_to, INTERVAL 1 DAY));

    SELECT a.audit_id, a.actor_type, a.actor_id, a.action, a.entity, a.entity_id,
           a.old_value, a.new_value, a.created_on
    FROM AuditLog a
    WHERE (p_entity IS NULL OR a.entity = p_entity)
      AND (p_entity_id IS NULL OR a.entity_id = p_entity_id)
      AND (p_actor_type IS NULL OR a.actor_type = p_actor_type)
      AND (p_actor_id IS NULL OR a.actor_id = p_actor_id)
      AND (p_date_from IS NULL OR a.created_on >= p_date_from)
      AND (p_date_to IS NULL OR a.created_on < DATE_ADD(p_date_to, INTERVAL 1 DAY))
    ORDER BY a.created_on DESC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
