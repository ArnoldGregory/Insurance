-- =====================================================================
-- PENDING MIGRATIONS - applied in one shot on the server
-- Target:  insurance_platform
-- Run as:  sudo mysql insurance_platform < apply_pending_migrations.sql
-- All sections are idempotent and safe to re-run.
-- Order is important: banded TPO schema/procs run first.
--
--  1. tpo_banded_pricing_migration.sql
--  2. commission_withdrawal_hardening.sql
--  3. motor_real_rates_2026.sql
--  4. motor_rates_2026_batch2.sql
--  5. usp_User_GetAgentCounts  (dashboard agent counts - was missing live)
--  6. verification SELECTs
-- =====================================================================
USE insurance_platform;


-- =====================================================================
-- TPO pricing: discrete capacity/tonnage -> BANDS
-- ---------------------------------------------------------------------
-- Why: underwriters rate Third Party Only by a RANGE (e.g. PSV 14-24
-- seats, commercial 3-8 tonnes). The old lookup matched carry_capacity/
-- tonnage EXACTLY, so a customer typing any value that wasn't one of the
-- few seeded buckets got no price at all, and a Private vehicle (which
-- sends capacity "1") matched nothing because its rows stored NULL.
--
-- This migration adds one band pair per row:
--   band_min / band_max  = the rating band in the class's rating unit
--                          (seats for PSV classes, tonnes for Commercial).
--                          both NULL = flat-rate class (Private, Motorcycle).
--                          band_max NULL with band_min set = open-ended.
-- and rewrites the three TPO procs to match an input value against the
-- band. Class dimension is decided from MotorVehicleClasses (requires_tonnage
-- -> tonnage; name PSV% -> capacity; else flat), so the caller can keep
-- passing whatever it already passes.
--
-- Legacy carry_capacity / tonnage columns are kept (backfilled into a
-- degenerate min=max band) so nothing already deployed breaks.
-- Idempotent: safe to re-run.
-- =====================================================================
USE insurance_platform;

-- ---------------------------------------------------------------------
-- 1) Add band columns if missing.
-- ---------------------------------------------------------------------
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TpoPriceMapping' AND COLUMN_NAME = 'band_min') = 0,
    'ALTER TABLE TpoPriceMapping ADD COLUMN band_min DECIMAL(10,2) NULL AFTER tonnage',
    'DO 0'));
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TpoPriceMapping' AND COLUMN_NAME = 'band_max') = 0,
    'ALTER TABLE TpoPriceMapping ADD COLUMN band_max DECIMAL(10,2) NULL AFTER band_min',
    'DO 0'));
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------
-- 2) Backfill legacy rows into a degenerate min=max band so existing
--    placeholder pricing keeps working until real rates replace it.
-- ---------------------------------------------------------------------
UPDATE TpoPriceMapping t
JOIN MotorVehicleClasses vc ON vc.vehicle_class_id = t.vehicle_class_id
SET t.band_min = CAST(t.carry_capacity AS DECIMAL(10,2)),
    t.band_max = CAST(t.carry_capacity AS DECIMAL(10,2))
WHERE t.band_min IS NULL
  AND vc.requires_tonnage = 0
  AND vc.name LIKE 'PSV%'
  AND t.carry_capacity IS NOT NULL
  AND t.carry_capacity REGEXP '^[0-9]+$';

UPDATE TpoPriceMapping t
JOIN MotorVehicleClasses vc ON vc.vehicle_class_id = t.vehicle_class_id
SET t.band_min = t.tonnage,
    t.band_max = t.tonnage
WHERE t.band_min IS NULL
  AND vc.requires_tonnage = 1
  AND t.tonnage IS NOT NULL;


DELIMITER $$

DROP PROCEDURE IF EXISTS usp_TpoPriceMapping_SetPrice $$
CREATE PROCEDURE usp_TpoPriceMapping_SetPrice (
    IN  p_underwriter_id     BIGINT UNSIGNED,
    IN  p_vehicle_class_id    BIGINT UNSIGNED,
    IN  p_period_id            BIGINT UNSIGNED,
    IN  p_band_min                DECIMAL(10,2),
    IN  p_band_max                  DECIMAL(10,2),
    IN  p_price                      DECIMAL(18,2),
    IN  p_effective_from                DATE,
    IN  p_actor_id                        BIGINT UNSIGNED,   -- Agent_admin
    OUT o_result_code                       INT,
    OUT o_result_message                      VARCHAR(500),
    OUT o_tpo_price_id                          BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_old_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error â€” transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_vehicle_class_id IS NULL OR p_period_id IS NULL OR p_price IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, vehicle_class_id, period_id and price are required.';
        LEAVE proc_label;
    END IF;

    IF p_price <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'price must be greater than zero.';
        LEAVE proc_label;
    END IF;

    IF p_band_min IS NULL AND p_band_max IS NOT NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'band_max requires band_min.';
        LEAVE proc_label;
    END IF;

    IF p_band_min IS NOT NULL AND p_band_max IS NOT NULL AND p_band_max < p_band_min THEN
        SET o_result_code = 1;
        SET o_result_message = 'band_max must be greater than or equal to band_min.';
        LEAVE proc_label;
    END IF;

    IF p_effective_from IS NULL THEN
        SET p_effective_from = CURDATE();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found or inactive.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM MotorVehicleClasses WHERE vehicle_class_id = p_vehicle_class_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle class not found.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Periods WHERE period_id = p_period_id AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Period not found or inactive.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    SELECT tpo_price_id INTO v_old_id
    FROM TpoPriceMapping
    WHERE underwriter_id = p_underwriter_id
      AND vehicle_class_id = p_vehicle_class_id
      AND period_id = p_period_id
      AND band_min <=> p_band_min
      AND band_max <=> p_band_max
      AND is_active = 1
    LIMIT 1
    FOR UPDATE;

    IF v_old_id IS NOT NULL THEN
        UPDATE TpoPriceMapping
        SET is_active = 0, effective_to = DATE_SUB(p_effective_from, INTERVAL 1 DAY)
        WHERE tpo_price_id = v_old_id;
    END IF;

    INSERT INTO TpoPriceMapping (underwriter_id, vehicle_class_id, period_id, band_min, band_max,
                                  price, effective_from, effective_to, is_active, created_by, created_on)
    VALUES (p_underwriter_id, p_vehicle_class_id, p_period_id, p_band_min, p_band_max,
            p_price, p_effective_from, NULL, 1, p_actor_id, NOW());

    SET o_tpo_price_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'TpoPriceMapping', o_tpo_price_id,
            IF(v_old_id IS NOT NULL, JSON_OBJECT('superseded_tpo_price_id', v_old_id), NULL),
            JSON_OBJECT('underwriter_id', p_underwriter_id, 'vehicle_class_id', p_vehicle_class_id,
                        'period_id', p_period_id, 'band_min', p_band_min, 'band_max', p_band_max,
                        'price', p_price, 'effective_from', p_effective_from),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_TpoPriceMapping_GetOptions $$
CREATE PROCEDURE usp_TpoPriceMapping_GetOptions (
    IN  p_vehicle_class_id BIGINT UNSIGNED,
    IN  p_period_id        BIGINT UNSIGNED,
    IN  p_carry_capacity   VARCHAR(50),
    IN  p_tonnage          DECIMAL(10,2),
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_requires_tonnage TINYINT DEFAULT 0;
    DECLARE v_class_name       VARCHAR(100) DEFAULT NULL;
    DECLARE v_value            DECIMAL(10,2) DEFAULT NULL;

    IF p_vehicle_class_id IS NULL OR p_period_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_class_id and period_id are required.';
        LEAVE proc_label;
    END IF;

    SELECT requires_tonnage, name INTO v_requires_tonnage, v_class_name
    FROM MotorVehicleClasses
    WHERE vehicle_class_id = p_vehicle_class_id;

    -- Pick the value the class is rated on: tonnage for Commercial, seating
    -- capacity for PSV-style classes, nothing (flat) for everything else.
    IF v_requires_tonnage = 1 THEN
        SET v_value = p_tonnage;
    ELSEIF v_class_name LIKE 'PSV%' THEN
        IF p_carry_capacity IS NOT NULL AND p_carry_capacity REGEXP '^[0-9]+([.][0-9]+)?$' THEN
            SET v_value = CAST(p_carry_capacity AS DECIMAL(10,2));
        END IF;
    END IF;

    SELECT t.tpo_price_id, t.underwriter_id, u.name AS underwriter_name, t.price
    FROM TpoPriceMapping t
    JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
    WHERE t.vehicle_class_id = p_vehicle_class_id
      AND t.period_id = p_period_id
      AND t.is_active = 1
      AND u.is_active = 1
      AND t.effective_from <= CURDATE()
      AND (t.effective_to IS NULL OR t.effective_to >= CURDATE())
      AND (
            -- banded row: input value falls inside [band_min, band_max]
            (v_value IS NOT NULL
             AND t.band_min IS NOT NULL
             AND v_value >= t.band_min
             AND (t.band_max IS NULL OR v_value <= t.band_max))
            OR
            -- flat row: no band; only used when the class has no rating value
            (v_value IS NULL AND t.band_min IS NULL AND t.band_max IS NULL)
          )
    ORDER BY t.price ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_TpoPriceMapping_GetList $$
CREATE PROCEDURE usp_TpoPriceMapping_GetList (
    IN  p_underwriter_id   BIGINT UNSIGNED,
    IN  p_vehicle_class_id BIGINT UNSIGNED,
    IN  p_active_only      TINYINT(1),
    IN  p_page_number      INT,
    IN  p_page_size        INT,
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500),
    OUT o_total_count      BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM TpoPriceMapping t
    WHERE (p_underwriter_id IS NULL OR t.underwriter_id = p_underwriter_id)
      AND (p_vehicle_class_id IS NULL OR t.vehicle_class_id = p_vehicle_class_id)
      AND (p_active_only IS NULL OR p_active_only = 0 OR t.is_active = 1);

    SELECT t.tpo_price_id, t.underwriter_id, u.name AS underwriter_name,
           t.vehicle_class_id, vc.name AS vehicle_class_name,
           t.period_id, per.name AS period_name,
           t.band_min, t.band_max, t.price, t.effective_from, t.effective_to, t.is_active
    FROM TpoPriceMapping t
    JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
    JOIN MotorVehicleClasses vc ON vc.vehicle_class_id = t.vehicle_class_id
    JOIN Periods per ON per.period_id = t.period_id
    WHERE (p_underwriter_id IS NULL OR t.underwriter_id = p_underwriter_id)
      AND (p_vehicle_class_id IS NULL OR t.vehicle_class_id = p_vehicle_class_id)
      AND (p_active_only IS NULL OR p_active_only = 0 OR t.is_active = 1)
    ORDER BY t.effective_from DESC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;

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
        SET o_result_message = 'Unexpected error â€” transaction rolled back.';
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
        SET o_result_message = 'Unexpected error â€” transaction rolled back.';
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

-- =====================================================================
-- Real motor underwriter rates â€” 2026
--   * Definite Assurance   Ref DAC/MOTOR/0001/2024  (+ DAC/PSV/0002/2025)
--   * Fidelity Shield      Ref FID/COMM/01/2026/UW   (21.01.2026)
--   * APA Insurance        Revised Motor Rates 2026  (new biz 12/01/2026)
-- =====================================================================
-- Where these land, and why:
--   * Comprehensive quote on the website is VALUE-BAND only (the customer
--     enters just a vehicle value) ->  ComprehensiveRateBand
--                                        ComprehensiveBenefit
--                                        ComprehensiveLiabilityLimit
--   * TPO is class + capacity/tonnage aware -> TpoPriceMapping
--   * Class-specific COMPREHENSIVE rates (the bulk of the commercial
--     documents) cannot be represented by the value-band table today;
--     they belong in ComprehensiveRateFormula (class-aware) and are
--     flagged as a follow-up at the bottom of this file.
--
-- Idempotent: every insert is guarded (JOIN / NOT EXISTS / ON DUPLICATE),
-- so this can be re-run safely and never wipes admin-edited rows.
-- =====================================================================
USE insurance_platform;

-- ---------------------------------------------------------------------
-- 1) UNDERWRITERS
--    Definite already exists (kept, never duplicated); Fidelity and APA
--    are new. Match on name so an existing row keeps its own code.
-- ---------------------------------------------------------------------
INSERT INTO Underwriters (name, code, is_active, created_on)
SELECT v.name, v.code, 1, NOW()
FROM (VALUES
        ROW('Definite Assurance', 'DEFINITE'),
        ROW('Fidelity Shield Insurance Company Limited', 'FID'),
        ROW('APA Insurance Limited', 'APA')
     ) AS v(name, code)
WHERE NOT EXISTS (SELECT 1 FROM Underwriters u WHERE u.name = v.name);


-- ---------------------------------------------------------------------
-- 2) COMPREHENSIVE RATE BANDS (private car, value bands)
--    Matches usp_ComprehensiveRateBand_GetOptions (value in / total out).
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveRateBand
    (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from)
SELECT uw.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, CURDATE()
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance - private (individual)
        ROW('DEFINITE',      500000,  1000000, 4.50, 30000),
        ROW('DEFINITE',     1000001,  2000000, 3.50, 30000),
        ROW('DEFINITE',     2000001, 999999999, 3.00, 30000),
        -- APA Insurance - private car
        ROW('APA',           600000,  1000000, 7.25, 50000),
        ROW('APA',          1000001,  1500000, 6.00, 50000),
        ROW('APA',          1500001,  2500000, 5.50, 50000),
        ROW('APA',          2500001,  5000000, 4.25, 50000),
        ROW('APA',          5000001, 10000000, 3.00, 50000),
        ROW('APA',         10000001, 999999999, 3.00, 50000)
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveRateBand rb
     WHERE rb.underwriter_id = uw.underwriter_id
       AND rb.value_min = b.value_min
       AND rb.value_max = b.value_max
);


-- ---------------------------------------------------------------------
-- 3) COMPREHENSIVE BENEFITS
--    Flat-price lines only. Percentage-based extras (excess protector,
--    PVT) are seeded at their DOCUMENTED MINIMUM as the add-on price.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price,
     is_included_in_base, description, display_order)
SELECT uw.underwriter_id, b.benefit_code, b.benefit_name, b.default_price,
       b.is_included_in_base, b.description, b.display_order
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance
        ROW('DEFINITE','EXCESS_PROTECTOR','Excess Protector',3000,0,'Own-damage excess waiver (0.25% of SI, min 3,000)',1),
        ROW('DEFINITE','PVT','Political Violence & Terrorism',0,1,'Included in base premium',2),
        ROW('DEFINITE','WINDSREEN','Windscreen',0,1,'Free windscreen cover',3),
        ROW('DEFINITE','TOWING','Towing / Recovery',0,1,'Free towing & recovery',4),
        ROW('DEFINITE','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        -- Fidelity Shield (commercial)
        ROW('FID','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.5% of SI, min 5,000)',1),
        ROW('FID','PVT','Political Violence & Terrorism',0,1,'Included in base premium',2),
        ROW('FID','WINDSREEN','Windscreen',0,1,'Free windscreen cover',3),
        ROW('FID','TOWING','Towing / Recovery',0,1,'Free towing / recovery',4),
        ROW('FID','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        ROW('FID','RADIO','Radio / CD Player',0,1,'Free radio / CD player cover',6),
        -- APA Insurance
        ROW('APA','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.25% of SI, min 5,000)',1),
        ROW('APA','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500 private / 5,000 commercial)',2),
        ROW('APA','WINDSREEN','Windscreen',0,1,'Free windscreen cover (50,000 / 100,000 limit)',3),
        ROW('APA','TOWING','Towing / Recovery',0,1,'Free towing cover',4),
        ROW('APA','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        ROW('APA','RADIO','Infotainment / Stereo Unit',0,1,'Free infotainment cover',6)
     ) AS b(uw_code, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveBenefit cb
     WHERE cb.underwriter_id = uw.underwriter_id
       AND cb.benefit_code = b.benefit_code
);


-- ---------------------------------------------------------------------
-- 4) COMPREHENSIVE LIABILITY LIMITS
--    ComprehensiveLiabilityLimit is per-underwriter (no class dimension),
--    so one representative commercial set is seeded per underwriter.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveLiabilityLimit
    (underwriter_id, limit_name, limit_value, display_order)
SELECT uw.underwriter_id, l.limit_name, l.limit_value, l.display_order
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance (standard commercial)
        ROW('DEFINITE','Third Party Property Damage','10,000,000',1),
        ROW('DEFINITE','Third Party Bodily Injury (per person)','3,000,000',2),
        ROW('DEFINITE','Third Party Bodily Injury (per event)','100,000,000',3),
        ROW('DEFINITE','Passenger Legal Liability (per person)','3,000,000',4),
        ROW('DEFINITE','Passenger Legal Liability (per event)','20,000,000',5),
        -- Fidelity Shield (commercial, representative set)
        ROW('FID','Third Party Property Damage','10,000,000',1),
        ROW('FID','Third Party Bodily Injury (per person)','3,000,000',2),
        ROW('FID','Third Party Bodily Injury (per event)','100,000,000',3),
        ROW('FID','Passenger Legal Liability (per person)','3,000,000',4),
        ROW('FID','Passenger Legal Liability (per event)','20,000,000',5),
        ROW('FID','Authorized Repair (free limit)','100,000',6),
        ROW('FID','Medical Expenses (free limit)','50,000',7),
        ROW('FID','Towing / Recovery','100,000',8),
        ROW('FID','Windscreen (free limit)','50,000',9),
        -- APA Insurance
        ROW('APA','Third Party Property Damage (free limit)','20,000,000',1),
        ROW('APA','Third Party Bodily Injury / PLL (per person)','3,000,000',2),
        ROW('APA','Third Party Bodily Injury / PLL (per event)','20,000,000',3),
        ROW('APA','Authorized Repair','50,000',4),
        ROW('APA','Emergency Medical Expenses','50,000',5),
        ROW('APA','Towing / Recovery','50,000',6),
        ROW('APA','Windscreen (0.6M - 2.5M / >2.5M)','50,000 / 100,000',7),
        ROW('APA','Infotainment / Stereo','50,000 / 100,000',8)
     ) AS l(uw_code, limit_name, limit_value, display_order)
  ON l.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveLiabilityLimit ll
     WHERE ll.underwriter_id = uw.underwriter_id
       AND ll.limit_name = l.limit_name
);


-- ---------------------------------------------------------------------
-- 5) OPTIONAL â€” retire the placeholder comprehensive underwriters so the
--    website compare shows only the real partners above.
--    Review before enabling; this only flips is_active, it does not delete.
-- ---------------------------------------------------------------------
-- UPDATE Underwriters
--    SET is_active = 0
--  WHERE code IN ('MONARCH','MUA','HERITAGE','PACIS','OLDMUTUAL','KENINDIA','KENYA_ORIENT');


-- =====================================================================
-- FOLLOW-UP (NOT in this file â€” needs confirmation):
--   * Commercial / PSV COMPREHENSIVE rates are class-specific and do not
--     fit the value-band table. They go in ComprehensiveRateFormula
--     (underwriter_id, vehicle_class_id, base_rate_percent, min_premium).
--   * TPO rates per class -> TpoPriceMapping (vehicle_class_id + period;
--     carry_capacity for PSV, tonnage for commercial).
--   * Fidelity Shield publishes NO private-car rates, so it has no value
--     bands here (commercial-only insurer).
-- =====================================================================

-- =====================================================================
-- Motor rates batch 2 â€” 2026 (docs-backed underwriters)
-- ---------------------------------------------------------------------
-- Sources (underwriting files, Oct 2026):
--   * KOIL RATES MOTOR 2024               -> Kenya Orient (KENYA_ORIENT)
--   * OLD MUTUAL MOTOR PRIVATE RATES       -> Old Mutual (OLDMUTUAL)
--   * MUA MOTOR VEHICLE TERMS â€” MAY 2025   -> MUA (MUA)
--   * Mornach / Monarch Motor Pricing 2025 -> Monarch (MONARCH)
--   * DEFINITE ASSURANCE APPROVED RATES    -> Definite (DEFINITE)
--   * RATES 2025 â€” PIONEER                  -> Pioneer (new: PIONEER)
--
-- Scope:
--   * ComprehensiveRateBand (private motor, value bands) â€” the only shape
--     the website's comprehensive compare consumes today.
--   * TpoPriceMapping â€” now BANDED (see tpo_banded_pricing_migration.sql):
--       band_min/band_max in the class's rating unit (seats for PSV, tonnes
--       for Commercial); NULL/NULL = flat-rate class (Private, Motorcycle).
--     Only periods a document actually publishes are seeded â€” insurers that
--     state "no short-term TPO" get an annual row only (no invented short
--     rates).
--
-- Deliberately NOT seeded (needs your call â€” see notes at the bottom):
--   * image-only PDFs: Heritage, APA 2026 update, Fidelity private update.
--   * ambiguous tables: Monarch/Pioneer comprehensive private rates.
--   * Commercial/PSV COMPREHENSIVE (needs the class-aware formula path).
--
-- Idempotent: rate-band/benefit/limit guarded by NOT EXISTS; TPO for the
-- underwriters reseeded here is cleared then re-inserted (same final state
-- on every run). Safe to re-run.
-- =====================================================================
USE insurance_platform;

-- ---------------------------------------------------------------------
-- 1) New underwriter: Pioneer
-- ---------------------------------------------------------------------
INSERT INTO Underwriters (name, code, is_active, created_on)
SELECT 'Pioneer Insurance', 'PIONEER', 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM Underwriters WHERE code = 'PIONEER');


-- ---------------------------------------------------------------------
-- 2) COMPREHENSIVE RATE BANDS (private motor)
--    Each doc's private-motor value bands, verbatim.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveRateBand
    (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from)
SELECT uw.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, CURDATE()
FROM Underwriters uw
JOIN (VALUES
        -- Kenya Orient (KOIL): min premium 35,000, max age 15
        ROW('KENYA_ORIENT',   500000,  1000000, 6.00, 35000),
        ROW('KENYA_ORIENT',  1000001,  2000000, 4.00, 35000),
        ROW('KENYA_ORIENT',  2000001,  3000000, 3.25, 35000),
        ROW('KENYA_ORIENT',  3000001, 999999999, 3.00, 35000),
        -- Old Mutual: min premium applies to first two bands only
        ROW('OLDMUTUAL',      500000,  1000000, 6.00, 37500),
        ROW('OLDMUTUAL',     1000001,  1500000, 5.00, 60000),
        ROW('OLDMUTUAL',     1500001,  2500000, 4.00,     0),
        ROW('OLDMUTUAL',     2500001,  2999999, 3.50,     0),
        ROW('OLDMUTUAL',     3000000,  4999999, 3.25,     0),
        ROW('OLDMUTUAL',     5000000, 999999999, 3.00,     0),
        -- MUA: min SI 500,000; excl. excess protector & PVT (included in rate)
        ROW('MUA',            500000,  2000000, 5.00, 45000),
        ROW('MUA',           2000001,  4000000, 3.50, 45000),
        ROW('MUA',           4000001, 999999999, 3.00, 45000)
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveRateBand rb
     WHERE rb.underwriter_id = uw.underwriter_id
       AND rb.value_min = b.value_min
       AND rb.value_max = b.value_max
);


-- ---------------------------------------------------------------------
-- 3) COMPREHENSIVE BENEFITS (flat price = documented minimum; % extras)
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price,
     is_included_in_base, description, display_order)
SELECT uw.underwriter_id, b.benefit_code, b.benefit_name, b.default_price,
       b.is_included_in_base, b.description, b.display_order
FROM Underwriters uw
JOIN (VALUES
        ROW('KENYA_ORIENT','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.25% of SI, min 5,000)',1),
        ROW('KENYA_ORIENT','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500)',2),
        ROW('KENYA_ORIENT','RESCUE','Garicorp Rescue Services',4500,0,'Rescue / roadside (4,500)',3),
        ROW('OLDMUTUAL','EXCESS_PROTECTOR','Excess Protector',2500,0,'Own-damage excess protector (0.25% of SI, min 2,500)',1),
        ROW('OLDMUTUAL','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500)',2),
        ROW('OLDMUTUAL','COURTESY_CAR','Courtesy Car',3000,0,'Courtesy car, 10 days, max 30,000',3),
        ROW('MUA','EXCESS_PROTECTOR','Excess Protector',0,1,'Included in base rate',1),
        ROW('MUA','PVT','Political Violence & Terrorism',0,1,'Included in base rate',2),
        ROW('MUA','TOWING','Towing / Recovery',0,1,'Free towing within Kenya',3),
        ROW('MUA','WINDSREEN','Windscreen',0,1,'Free limit 50,000 (SI <=2M) / 100,000 (SI >2M)',4)
     ) AS b(uw_code, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveBenefit cb
     WHERE cb.underwriter_id = uw.underwriter_id
       AND cb.benefit_code = b.benefit_code
);


-- ---------------------------------------------------------------------
-- 4) COMPREHENSIVE LIABILITY LIMITS (where the doc publishes them)
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveLiabilityLimit
    (underwriter_id, limit_name, limit_value, display_order)
SELECT uw.underwriter_id, l.limit_name, l.limit_value, l.display_order
FROM Underwriters uw
JOIN (VALUES
        ROW('OLDMUTUAL','Third Party Persons (per person)','10,000,000',1),
        ROW('OLDMUTUAL','Third Party Persons (per period)','100,000,000',2),
        ROW('OLDMUTUAL','Third Party Property Damage','30,000,000',3),
        ROW('OLDMUTUAL','Passenger Liability (per person)','4,000,000',4),
        ROW('OLDMUTUAL','Passenger Liability (per event)','20,000,000',5),
        ROW('OLDMUTUAL','Towing & Recovery','100,000',6),
        ROW('OLDMUTUAL','Repair Authority','100,000',7),
        ROW('OLDMUTUAL','Medical Expenses','100,000',8),
        ROW('OLDMUTUAL','Entertainment Systems','100,000',9),
        ROW('OLDMUTUAL','Windscreen / Window Glass','100,000',10)
     ) AS l(uw_code, limit_name, limit_value, display_order)
  ON l.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveLiabilityLimit ll
     WHERE ll.underwriter_id = uw.underwriter_id
       AND ll.limit_name = l.limit_name
);


-- ---------------------------------------------------------------------
-- 5) TPO â€” clear the underwriters we are reseeding, then insert real bands.
--    (Their previous rows are placeholder values, not underwriter data.)
--    These six underwriters' TPO is fully owned by this file, so we DELETE
--    their rows and re-insert: that gives the same final state on every run
--    (a soft-deactivate still works but piling up dead rows). No table has
--    an FK to TpoPriceMapping, so the delete is safe.
--    Periods are matched BY NAME, not by hardcoded id, so it is not
--    sensitive to the id numbering of the Periods table.
-- ---------------------------------------------------------------------
DELETE t
FROM TpoPriceMapping t
JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
WHERE u.code IN ('MONARCH','MUA','KENYA_ORIENT','OLDMUTUAL','DEFINITE','PIONEER');

INSERT INTO TpoPriceMapping
    (underwriter_id, vehicle_class_id, period_id, band_min, band_max,
     price, effective_from, effective_to, is_active, created_on)
SELECT u.underwriter_id, vc.vehicle_class_id, p.period_id, x.band_min, x.band_max,
       x.price, CURDATE(), NULL, 1, NOW()
FROM (VALUES
        -- ===== DEFINITE ASSURANCE (Ref DAC/MOTOR/0001/2024) =====
        -- Motor private: TPO 4,500 (annual)
        ROW('DEFINITE','PRIVATE','1 Year',NULL,NULL,4500),
        -- Motor cycle non-PSV: 2,000 ; PSV: annual 3,500 / 6mo 2,000 / monthly 1,000
        ROW('DEFINITE','MOTORCYCLE:PRIVATE','1 Year',NULL,NULL,2000),
        ROW('DEFINITE','MOTORCYCLE:PSV','1 Year',NULL,NULL,3500),
        ROW('DEFINITE','MOTORCYCLE:PSV','6 Months',NULL,NULL,2000),
        ROW('DEFINITE','MOTORCYCLE:PSV','1 Month',NULL,NULL,1000),
        -- Tuk Tuk PSV: annual 4,500 / monthly 1,000
        ROW('DEFINITE','PSV-TAXI / TUK TUK','1 Year',NULL,NULL,4500),
        ROW('DEFINITE','PSV-TAXI / TUK TUK','1 Month',NULL,NULL,1000),
        -- Private Hire chauffeur/Taxi: <=9 5,500 / 10-17 8,500 / 18-25 12,500 / >25 15,500
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber','1 Year',0,9,5500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber','1 Year',9.01,17,8500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber','1 Year',17.01,25,12500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber','1 Year',25.01,NULL,15500),
        -- Own goods / general cartage hybrid: <=3t 5,500 / 3-8t 7,500 / >8t 9,500
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS','1 Year',0,3,5500),
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS','1 Year',3.01,8,7500),
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS','1 Year',8.01,NULL,9500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL','1 Year',0,3,5500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL','1 Year',3.01,8,7500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL','1 Year',8.01,NULL,9500),
        ROW('DEFINITE','MOTOR COMMERCIAL:Prime Mover','1 Year',NULL,NULL,15000),
        ROW('DEFINITE','MOTOR COMMERCIAL:TRACTOR','1 Year',NULL,NULL,3000),

        -- ===== MUA INSURANCE (May 2025) =====
        ROW('MUA','PRIVATE','1 Year',NULL,NULL,12500),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS','1 Year',0,3,15000),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS','1 Year',3.01,8,20000),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS','1 Year',8.01,NULL,25000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL','1 Year',0,8,25000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL','1 Year',8.01,20,30000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL','1 Year',20.01,30,35000),
        ROW('MUA','MOTOR COMMERCIAL:Prime Mover','1 Year',NULL,NULL,30000),

        -- ===== KENYA ORIENT (KOIL 2024) =====
        ROW('KENYA_ORIENT','PRIVATE','1 Year',NULL,NULL,7574),
        ROW('KENYA_ORIENT','MOTORCYCLE:PRIVATE','1 Year',NULL,NULL,5000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:OWN GOODS','1 Year',0,3,7500),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:OWN GOODS','1 Year',3.01,8,12000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:GENERAL','1 Year',8.01,20,20000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:GENERAL','1 Year',20.01,30,25000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Prime Mover','1 Year',NULL,NULL,20000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer','1 Year',0,10,17500),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer','1 Year',10.01,20,25000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer','1 Year',20.01,30,30000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer','1 Year',30.01,NULL,35000),

        -- ===== MONARCH (Motor Pricing 2025) =====
        ROW('MONARCH','MOTORCYCLE:PRIVATE','1 Year',NULL,NULL,2000),
        ROW('MONARCH','MOTORCYCLE:PSV','1 Year',NULL,NULL,3000),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',0,3.49,4500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',3.5,8.49,5500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',8.5,12.49,6500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',12.5,15.49,7500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',15.5,20,10000),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS','1 Year',20.01,NULL,15000),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',0,3.49,4500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',3.5,8.49,5500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',8.5,12.49,6500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',12.5,15.49,7500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',15.5,20,10000),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL','1 Year',20.01,NULL,15000),
        ROW('MONARCH','MOTOR COMMERCIAL:Prime Mover','1 Year',NULL,NULL,10000),

        -- ===== PIONEER (Rates 2025) â€” School Bus TPO bands =====
        ROW('PIONEER','PSV-BUS','1 Year',0,14,7500),
        ROW('PIONEER','PSV-BUS','1 Year',14.01,25,12500),
        ROW('PIONEER','PSV-BUS','1 Year',25.01,NULL,18000)
     ) AS x(uw_code, class_name, period_name, band_min, band_max, price)
JOIN Underwriters u ON u.code = x.uw_code
JOIN MotorVehicleClasses vc ON vc.name = x.class_name
JOIN Periods p ON p.name = x.period_name AND p.is_active = 1;


-- ---------------------------------------------------------------------
-- 6) RETIRE FABRICATED PLACEHOLDER RATES
--    Underwriters with no rate document in the current set only have
--    fabricated placeholders, which would otherwise compete with the real
--    partners. Deactivate (never delete) â€” fully reversible, and only
--    flips is_active.
-- ---------------------------------------------------------------------
-- 6a) No documented rates at all -> hide the underwriter entirely.
UPDATE Underwriters SET is_active = 0
 WHERE code IN ('HERITAGE','PACIS','KENINDIA');

-- 6b) Fabricated COMPREHENSIVE bands for underwriters whose docs give no
--     readable comprehensive private rates (Monarch keeps its real TPO).
UPDATE ComprehensiveRateBand rb
JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
   SET rb.is_active = 0
 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA','MONARCH');

-- 6c) Fabricated TPO for the fully-retired placeholders. Their underwriter
--     is already inactive (so the API hides them), but flip the TPO rows
--     too so no stale active prices linger in the table.
UPDATE TpoPriceMapping t
JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
   SET t.is_active = 0
 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA') AND t.is_active = 1;

-- To bring them back once real rates arrive:
--   UPDATE Underwriters SET is_active = 1 WHERE code IN ('HERITAGE','PACIS','KENINDIA');
--   UPDATE ComprehensiveRateBand rb JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
--     SET rb.is_active = 1 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA','MONARCH');
--   UPDATE TpoPriceMapping t JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
--     SET t.is_active = 1 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA');


-- =====================================================================
-- NOT SEEDED â€” needs confirmation (documented, not guessed):
--   * Heritage new motor private terms, APA 13-01-2026 revision and the
--     Fidelity private underwriting update are IMAGE-ONLY / unreadable, so
--     no figures could be extracted (need OCR or a typed copy).
--   * Monarch / Pioneer COMPREHENSIVE private rates: the rate tables did
--     not line up with their column headings in extraction, so no private
--     rate bands were seeded for them.
--   * Commercial / PSV COMPREHENSIVE: class-specific, cannot be expressed
--     by the value-band table â€” belongs in ComprehensiveRateFormula
--     (underwriter + vehicle_class + base rate + min premium).
--   * Short-term (weekly / 2-week / 6-month) TPO: most insurers state
--     "no short-term TPO only cover"; only periods a doc publishes were
--     seeded. Definite PSV capacity table (DAC/PSV/0002/2025) is the one
--     source with explicit 7/14/30-day PSV TPO â€” seed separately if wanted.
--   * The website TPO form sends no TONNAGE, so Commercial tonnage bands
--     above are usable from the Admin purchase wizard but not yet from the
--     public site (needs a tonnage input on the Details page).
-- =====================================================================



-- =====================================================================
-- 5) usp_User_GetAgentCounts - dashboard "Total Agents" / "Active Agents".
--    The live DB was missing this proc (endpoint returned an error);
--    definition matches the repo copy in Insurance_API_StoredProcs_Auth.sql.
-- =====================================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS usp_User_GetAgentCounts $$
CREATE PROCEDURE usp_User_GetAgentCounts (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT
        COUNT(DISTINCT u.user_id) AS total_agent_count,
        COUNT(DISTINCT CASE WHEN pu.purchase_id IS NOT NULL THEN u.user_id END) AS active_agent_count
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id AND r.role_code = 'AG'
    LEFT JOIN Purchases pu ON pu.purchased_by_user_id = u.user_id
                           AND pu.created_on >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    WHERE u.isdeleted = 0;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;

-- =====================================================================
-- 5b) usp_Purchase_GetById - restore the NTSA-aware definition.
--     The master file Insurance_API_StoredProcs_PurchasesPayments.sql
--     shipped an older GetById WITHOUT the NTSA columns; re-running it
--     silently overwrote the D-MVIC version, so GET /api/purchases/{id}
--     threw "The column name 'ntsa_certificate_no' does not exist".
--     Guard the columns (idempotent), then recreate the proc body.
-- =====================================================================

SET @col_exists := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Purchases'
      AND COLUMN_NAME = 'ntsa_certificate_no'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE Purchases
        ADD COLUMN ntsa_certificate_no VARCHAR(100) NULL AFTER certificate_number,
        ADD COLUMN ntsa_transaction_no VARCHAR(100) NULL AFTER ntsa_certificate_no,
        ADD COLUMN ntsa_issued_on DATETIME NULL AFTER ntsa_transaction_no',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DELIMITER $$

DROP PROCEDURE IF EXISTS usp_Purchase_GetById $$
CREATE PROCEDURE usp_Purchase_GetById (
    IN  p_purchase_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_purchase_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    SELECT pu.purchase_id, pu.product_id, pr.code AS product_code, pr.name AS product_name, pu.client_id,
           c.full_name AS client_name, c.id_no AS client_id_no, c.phone AS client_phone, c.email AS client_email,
           pu.purchased_by_user_id, pu.channel_service_account_id, pu.underwriter_id,
           u.name AS underwriter_name, pu.quote_offer_id, pu.premium_amount, pu.period_id,
           per.name AS period_name, pu.start_date, pu.end_date, pu.policy_number,
           pu.payment_status, pu.status, pu.created_on,
           pu.certificate_status, pu.cert_generated_on, pu.certificate_number,
           pu.ntsa_certificate_no, pu.ntsa_transaction_no, pu.ntsa_issued_on,
           v.reg_no AS vehicle_reg_no, v.make AS vehicle_make, v.model AS vehicle_model
    FROM Purchases pu
    JOIN Products pr ON pr.product_id = pu.product_id
    JOIN Underwriters u ON u.underwriter_id = pu.underwriter_id
    JOIN Periods per ON per.period_id = pu.period_id
    LEFT JOIN Clients c ON c.client_id = pu.client_id
    LEFT JOIN VehiclePurchaseSnapshot vps ON vps.purchase_id = pu.purchase_id
    LEFT JOIN Vehicles v ON v.vehicle_id = vps.vehicle_id
    WHERE pu.purchase_id = p_purchase_id
    LIMIT 1;

    SELECT snapshot_id, vehicle_id, vehicle_value, tonnage, licensedtocarry, antitheft, risk, amount
    FROM VehiclePurchaseSnapshot
    WHERE purchase_id = p_purchase_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;

-- =====================================================================
-- 6) VERIFICATION
-- =====================================================================

-- 6a) dashboard agent counts resolve
CALL usp_User_GetAgentCounts(@c,@m);
SELECT @c AS result_code, @m AS result_message;

-- 6b) comprehensive value-bands for Definite / APA
SELECT uw.name, rb.value_min, rb.value_max, rb.rate_percent, rb.min_premium
FROM ComprehensiveRateBand rb
JOIN Underwriters uw USING(underwriter_id)
WHERE uw.code IN ('DEFINITE','APA')
ORDER BY uw.name, rb.value_min;

-- 6c) active underwriters (only the real partners should be is_active=1)
SELECT code, name, is_active FROM Underwriters ORDER BY is_active DESC, code;

-- 6d) banded TPO rows (active only)
SELECT u.code, c.name AS class, t.band_min, t.band_max, t.price
FROM TpoPriceMapping t
JOIN Underwriters u USING(underwriter_id)
JOIN MotorVehicleClasses c USING(vehicle_class_id)
WHERE u.code IN ('DEFINITE','MUA','KENYA_ORIENT','MONARCH','PIONEER')
  AND t.is_active = 1
ORDER BY u.code, c.name, t.band_min;

-- 6e) confirm the new/updated procs are present
SELECT ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA='insurance_platform'
  AND ROUTINE_NAME IN ('usp_CommissionWithdrawal_Request',
                       'usp_CommissionWithdrawal_UpdateStatus',
                       'usp_User_GetAgentCounts',
                       'usp_TpoPriceMapping_SetPrice',
                       'usp_TpoPriceMapping_GetOptions');

-- 6f) usp_Purchase_GetById now exposes the NTSA certificate columns
--     (returns a row only when the fix is in place)
SELECT ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA='insurance_platform'
  AND ROUTINE_NAME='usp_Purchase_GetById'
  AND ROUTINE_DEFINITION LIKE '%ntsa_certificate_no%';

