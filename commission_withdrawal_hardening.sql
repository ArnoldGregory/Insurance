-- =====================================================================
-- Commission withdrawal hardening
-- ---------------------------------------------------------------------
-- Fixes the two real defects seen in production:
--   1. An agent could fire two withdrawal requests at once (two devices /
--      two sessions) and both read the same "available balance" before
--      either committed -> the balance was paid out twice -> negative.
--   2. A "minimum withdrawal" floor was never enforced.
--
-- Design (kept in the DB, per requirement):
--   * usp_CommissionWithdrawal_Request takes a per-agent named lock
--     (GET_LOCK) for the whole read-modify-write, so concurrent requests
--     for the same agent are serialized. The second request wakes up,
--     re-reads the now-reserved balance and is correctly rejected.
--   * The available balance is (re)computed under the lock; a request can
--     never reserve more than what is really there.
--   * A minimum withdrawal amount (v_min_withdrawal) is enforced here.
--   * usp_CommissionWithdrawal_UpdateStatus re-reads the row FOR UPDATE
--     inside the transaction so two admins cannot finalize it twice.
--
-- Signatures are unchanged, so no C# change is required.
-- Idempotent: safe to run repeatedly.
-- =====================================================================

USE insurance_platform;

DELIMITER $$

DROP PROCEDURE IF EXISTS usp_CommissionWithdrawal_Request $$
CREATE PROCEDURE usp_CommissionWithdrawal_Request (
    IN  p_agent_user_id  BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_withdrawal_id  BIGINT UNSIGNED,
    OUT o_amount         DECIMAL(18,2)
)
proc_label: BEGIN
    -- Minimum an agent may withdraw in a single request. Change this one
    -- constant to move the floor for everyone (policy lives in the DB).
    DECLARE v_min_withdrawal DECIMAL(18,2) DEFAULT 30.00;
    DECLARE v_lock_name      VARCHAR(64);
    DECLARE v_lock_acquired  INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        IF v_lock_acquired = 1 THEN
            DO RELEASE_LOCK(v_lock_name);
        END IF;
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    SET o_withdrawal_id = NULL;
    SET o_amount        = 0;

    IF p_agent_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'agent_user_id is required.';
        LEAVE proc_label;
    END IF;

    SET v_lock_name = CONCAT('cw_agent_', p_agent_user_id);

    -- Serialize every withdrawal request for this agent across all
    -- sessions/devices. 0 = timed out, NULL = error.
    SELECT GET_LOCK(v_lock_name, 10) INTO v_lock_acquired;
    IF v_lock_acquired <> 1 THEN
        SET o_result_code = 5;
        SET o_result_message = 'Another withdrawal for this agent is already in progress. Please try again.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    SELECT COALESCE(SUM(commission_amount), 0) INTO o_amount
    FROM AgentCommissions
    WHERE agent_user_id = p_agent_user_id AND status = 'ACCRUED' AND withdrawal_id IS NULL
    FOR UPDATE;

    IF o_amount IS NULL OR o_amount <= 0 THEN
        ROLLBACK;
        DO RELEASE_LOCK(v_lock_name);
        SET o_result_code = 4;
        SET o_result_message = 'No available commission balance to withdraw.';
        LEAVE proc_label;
    END IF;

    IF o_amount < v_min_withdrawal THEN
        ROLLBACK;
        DO RELEASE_LOCK(v_lock_name);
        SET o_result_code = 6;
        SET o_result_message = CONCAT('The minimum withdrawal amount is ', FORMAT(v_min_withdrawal, 2), '.');
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

    DO RELEASE_LOCK(v_lock_name);

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

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

    START TRANSACTION;

    -- Lock the row so two admins processing the same request at the same
    -- time cannot both pass the "already finalized" check below.
    SELECT status INTO v_old_status
    FROM CommissionWithdrawals
    WHERE withdrawal_id = p_withdrawal_id
    FOR UPDATE;

    IF v_old_status IS NULL THEN
        ROLLBACK;
        SET o_result_code = 2;
        SET o_result_message = 'Withdrawal request not found.';
        LEAVE proc_label;
    END IF;

    IF v_old_status IN ('PAID','REJECTED') THEN
        ROLLBACK;
        SET o_result_code = 4;
        SET o_result_message = 'This withdrawal has already been finalized.';
        LEAVE proc_label;
    END IF;

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

DELIMITER ;
