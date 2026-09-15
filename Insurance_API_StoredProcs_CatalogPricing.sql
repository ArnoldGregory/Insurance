-- =====================================================================
-- Insurance Platform — Stored Procedures: CATALOG / PRICING (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Covers: Underwriters CRUD, read-only lookups for Products /
-- MotorCategories / MotorVehicleClasses / Periods (fixed reference data,
-- seeded once — no write procs for these four), TPO price mapping
-- (set + lookup), Comprehensive rate formula (set + factors + premium
-- calculation).
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- =====================================================================
-- UNDERWRITERS
-- =====================================================================

DROP PROCEDURE IF EXISTS usp_Underwriter_Create $$
CREATE PROCEDURE usp_Underwriter_Create (
    IN  p_name            VARCHAR(150),
    IN  p_code             VARCHAR(20),
    IN  p_contact_email     VARCHAR(150),
    IN  p_contact_phone      VARCHAR(20),
    IN  p_actor_id             BIGINT UNSIGNED,   -- Agent_admin
    OUT o_result_code          INT,
    OUT o_result_message         VARCHAR(500),
    OUT o_underwriter_id           BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_name IS NULL OR p_code IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'name and code are required.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Underwriters WHERE code = p_code) THEN
        SET o_result_code = 3;
        SET o_result_message = 'An underwriter with this code already exists.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Underwriters (name, code, contact_email, contact_phone, is_active, created_by, created_on)
    VALUES (p_name, p_code, p_contact_email, p_contact_phone, 1, p_actor_id, NOW());

    SET o_underwriter_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'Underwriters', o_underwriter_id,
            NULL, JSON_OBJECT('name', p_name, 'code', p_code), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Underwriter_GetById $$
CREATE PROCEDURE usp_Underwriter_GetById (
    IN  p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    SELECT underwriter_id, name, code, contact_email, contact_phone, is_active, dmvic_code, policy_type, created_on
    FROM Underwriters
    WHERE underwriter_id = p_underwriter_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Underwriter_GetList $$
CREATE PROCEDURE usp_Underwriter_GetList (
    IN  p_active_only INT,   -- 1 = only is_active=1, 0/NULL = all
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    SELECT underwriter_id, name, code, contact_email, contact_phone, is_active, policy_type, created_on
    FROM Underwriters
    WHERE (p_active_only IS NULL OR p_active_only = 0 OR is_active = 1)
    ORDER BY name;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Underwriter_Update $$
CREATE PROCEDURE usp_Underwriter_Update (
    IN  p_underwriter_id   BIGINT UNSIGNED,
    IN  p_name             VARCHAR(150),
    IN  p_contact_email    VARCHAR(150),
    IN  p_contact_phone    VARCHAR(20),
    IN  p_actor_id         BIGINT UNSIGNED,
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old JSON;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT JSON_OBJECT('name', name, 'contact_email', contact_email, 'contact_phone', contact_phone)
    INTO v_old FROM Underwriters WHERE underwriter_id = p_underwriter_id;

    IF v_old IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Underwriters
    SET name          = COALESCE(p_name, name),
        contact_email = COALESCE(p_contact_email, contact_email),
        contact_phone = COALESCE(p_contact_phone, contact_phone)
    WHERE underwriter_id = p_underwriter_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'Underwriters', p_underwriter_id,
            v_old, JSON_OBJECT('name', p_name, 'contact_email', p_contact_email, 'contact_phone', p_contact_phone), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Underwriter_SetActiveStatus $$
CREATE PROCEDURE usp_Underwriter_SetActiveStatus (
    IN  p_underwriter_id BIGINT UNSIGNED,
    IN  p_is_active      TINYINT(1),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_is_active IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id and is_active are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Underwriters SET is_active = p_is_active WHERE underwriter_id = p_underwriter_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'STATUS_CHANGE', 'Underwriters', p_underwriter_id,
            NULL, JSON_OBJECT('is_active', p_is_active), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Underwriter_SetPolicyType
-- Sets whether this underwriter reuses one FIXED policy_number per
-- policy_level (see UnderwriterPolicyLevelNumber below) or not (CHANGE -
-- today that still means usp_Purchase_Create's own auto-generated
-- number). A separate, small, dedicated proc rather than folding this
-- into usp_Underwriter_Update, so that proc's existing signature/
-- parameter order never has to change.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Underwriter_SetPolicyType $$
CREATE PROCEDURE usp_Underwriter_SetPolicyType (
    IN  p_underwriter_id BIGINT UNSIGNED,
    IN  p_policy_type    VARCHAR(20),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_policy_type IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id and policy_type are required.';
        LEAVE proc_label;
    END IF;

    IF p_policy_type NOT IN ('FIXED','CHANGE') THEN
        SET o_result_code = 1;
        SET o_result_message = 'policy_type must be FIXED or CHANGE.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Underwriters SET policy_type = p_policy_type WHERE underwriter_id = p_underwriter_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'Underwriters', p_underwriter_id,
            NULL, JSON_OBJECT('policy_type', p_policy_type), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- =====================================================================
-- UNDERWRITER POLICY LEVEL NUMBER — ONE fixed, reused policy_number per
-- (underwriter, policy_level), meaningful for policy_type='FIXED'
-- underwriters only. See the CREATE TABLE UnderwriterPolicyLevelNumber
-- comment in Insurance_API_Schema.sql for the full design reasoning
-- (this replaces an earlier, incorrect "consumable pool" version of this
-- feature - no is_used/consumption concept exists here at all).
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_UnderwriterPolicyLevelNumber_Set
-- Upsert: registers the fixed number for (underwriter, policy_level) if
-- none exists yet, or corrects it in place if one already does - a
-- single idempotent action rather than separate Create/Update procs,
-- since there is exactly one row per (underwriter_id, policy_level_id)
-- by design (uq_upln_underwriter_level).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterPolicyLevelNumber_Set $$
CREATE PROCEDURE usp_UnderwriterPolicyLevelNumber_Set (
    IN  p_underwriter_id   BIGINT UNSIGNED,
    IN  p_policy_level_id  INT UNSIGNED,
    IN  p_policy_number    VARCHAR(50),
    IN  p_actor_id         BIGINT UNSIGNED,
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500),
    OUT o_id               BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_existing_id BIGINT UNSIGNED;
    DECLARE v_old_policy_number VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_policy_level_id IS NULL OR p_policy_number IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, policy_level_id and policy_number are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    SELECT id, policy_number INTO v_existing_id, v_old_policy_number
    FROM UnderwriterPolicyLevelNumber
    WHERE underwriter_id = p_underwriter_id AND policy_level_id = p_policy_level_id AND isdeleted = 0;

    START TRANSACTION;

    IF v_existing_id IS NULL THEN
        INSERT INTO UnderwriterPolicyLevelNumber (underwriter_id, policy_level_id, policy_number, created_by, created_on)
        VALUES (p_underwriter_id, p_policy_level_id, p_policy_number, p_actor_id, NOW());

        SET o_id = LAST_INSERT_ID();

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES ('USER', p_actor_id, 'CREATE', 'UnderwriterPolicyLevelNumber', o_id,
                NULL, JSON_OBJECT('underwriter_id', p_underwriter_id, 'policy_level_id', p_policy_level_id, 'policy_number', p_policy_number), NOW());
    ELSE
        UPDATE UnderwriterPolicyLevelNumber
        SET policy_number = p_policy_number
        WHERE id = v_existing_id;

        SET o_id = v_existing_id;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES ('USER', p_actor_id, 'UPDATE', 'UnderwriterPolicyLevelNumber', o_id,
                JSON_OBJECT('policy_number', v_old_policy_number), JSON_OBJECT('policy_number', p_policy_number), NOW());
    END IF;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_UnderwriterPolicyLevelNumber_GetList
-- Small reference-data listing (at most one row per underwriter+level,
-- so no pagination) - optionally filtered to one underwriter.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterPolicyLevelNumber_GetList $$
CREATE PROCEDURE usp_UnderwriterPolicyLevelNumber_GetList (
    IN  p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    SELECT n.id, n.underwriter_id, u.name AS underwriter_name, u.policy_type,
           n.policy_level_id, n.policy_number, n.created_on
    FROM UnderwriterPolicyLevelNumber n
    JOIN Underwriters u ON u.underwriter_id = n.underwriter_id
    WHERE n.isdeleted = 0
      AND (p_underwriter_id IS NULL OR n.underwriter_id = p_underwriter_id)
    ORDER BY n.underwriter_id ASC, n.policy_level_id ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- =====================================================================
-- REFERENCE DATA (read-only) — Products, MotorCategories,
-- MotorVehicleClasses, Periods. Fixed/seeded taxonomy; not managed
-- via API in this version.
-- =====================================================================

DROP PROCEDURE IF EXISTS usp_Product_GetList $$
CREATE PROCEDURE usp_Product_GetList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT product_id, name, code, pricing_method, is_active
    FROM Products
    WHERE is_active = 1
    ORDER BY name;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_MotorCategory_GetList $$
CREATE PROCEDURE usp_MotorCategory_GetList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT mc.motor_category_id, mc.product_id, mc.name
    FROM MotorCategories mc
    ORDER BY mc.name;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_MotorVehicleClass_GetList $$
CREATE PROCEDURE usp_MotorVehicleClass_GetList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT vehicle_class_id, name, requires_tonnage, policy_level_id
    FROM MotorVehicleClasses
    ORDER BY name;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_PolicyLevel_GetList $$
CREATE PROCEDURE usp_PolicyLevel_GetList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT policy_level_id, name
    FROM PolicyLevels
    ORDER BY policy_level_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Period_GetList $$
CREATE PROCEDURE usp_Period_GetList (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT period_id, name, dmvic_code
    FROM Periods
    WHERE is_active = 1 AND isdeleted = 0
    ORDER BY period_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- TPO PRICE MAPPING
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_TpoPriceMapping_SetPrice
-- Insert-only history pattern (matches AgentCommissionOverrides): closes
-- out the currently active row for the same underwriter+vehicle_class+
-- period+carry_capacity+tonnage combination (if one exists), then inserts
-- the new price as a fresh row. Nothing is ever overwritten in place, so
-- "what was the TPO price on date X" is always answerable.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_TpoPriceMapping_SetPrice $$
CREATE PROCEDURE usp_TpoPriceMapping_SetPrice (
    IN  p_underwriter_id     BIGINT UNSIGNED,
    IN  p_vehicle_class_id    BIGINT UNSIGNED,
    IN  p_period_id            BIGINT UNSIGNED,
    IN  p_carry_capacity         VARCHAR(50),
    IN  p_tonnage                  DECIMAL(10,2),
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
        SET o_result_message = 'Unexpected error — transaction rolled back.';
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
      AND carry_capacity <=> p_carry_capacity
      AND tonnage <=> p_tonnage
      AND is_active = 1
    LIMIT 1
    FOR UPDATE;

    IF v_old_id IS NOT NULL THEN
        UPDATE TpoPriceMapping
        SET is_active = 0, effective_to = DATE_SUB(p_effective_from, INTERVAL 1 DAY)
        WHERE tpo_price_id = v_old_id;
    END IF;

    INSERT INTO TpoPriceMapping (underwriter_id, vehicle_class_id, period_id, carry_capacity, tonnage,
                                  price, effective_from, effective_to, is_active, created_by, created_on)
    VALUES (p_underwriter_id, p_vehicle_class_id, p_period_id, p_carry_capacity, p_tonnage,
            p_price, p_effective_from, NULL, 1, p_actor_id, NOW());

    SET o_tpo_price_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'TpoPriceMapping', o_tpo_price_id,
            IF(v_old_id IS NOT NULL, JSON_OBJECT('superseded_tpo_price_id', v_old_id), NULL),
            JSON_OBJECT('underwriter_id', p_underwriter_id, 'vehicle_class_id', p_vehicle_class_id,
                        'period_id', p_period_id, 'price', p_price, 'effective_from', p_effective_from),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_TpoPriceMapping_GetOptions
-- The core pricing lookup called by the quote/purchase flow - NOT scoped
-- to one underwriter. A shopper (Agent, SupportAgent, etc.) picks a
-- vehicle_class_id+period_id+carry_capacity/tonnage combination (from
-- GET /api/products/motor-vehicle-classes and /periods) and this returns
-- every underwriter currently pricing that exact combination, cheapest
-- first, so the caller can compare and choose who to buy from. (Earlier
-- version of this proc, usp_TpoPriceMapping_GetPrice, took an
-- underwriter_id and returned a single price - dropped, since the
-- shopping flow needs options to compare, not one price the caller has
-- to already know an underwriter to ask for. usp_TpoPriceMapping_SetPrice,
-- the admin-side management proc, keeps its own underwriter_id param and
-- inline duplicate-check - unaffected by this change.)
-- Matches on carry_capacity for PSV-style classes or tonnage for
-- Commercial classes (whichever the caller passes — pass NULL for the one
-- that doesn't apply, per MotorVehicleClasses.requires_tonnage).
-- Returns zero rows (not an error) if no underwriter currently prices
-- this combination - same "empty list is a valid result" shape as
-- usp_TpoPriceMapping_GetList, not a NOT_FOUND business failure.
-- ---------------------------------------------------------------------
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
    IF p_vehicle_class_id IS NULL OR p_period_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_class_id and period_id are required.';
        LEAVE proc_label;
    END IF;

    SELECT t.tpo_price_id, t.underwriter_id, u.name AS underwriter_name, t.price
    FROM TpoPriceMapping t
    JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
    WHERE t.vehicle_class_id = p_vehicle_class_id
      AND t.period_id = p_period_id
      AND t.carry_capacity <=> p_carry_capacity
      AND t.tonnage <=> p_tonnage
      AND t.is_active = 1
      AND u.is_active = 1
      AND t.effective_from <= CURDATE()
      AND (t.effective_to IS NULL OR t.effective_to >= CURDATE())
    ORDER BY t.price ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_TpoPriceMapping_GetList
-- For Agent_admin's price-management screen. Filterable, paginated.
-- ---------------------------------------------------------------------
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
           t.carry_capacity, t.tonnage, t.price, t.effective_from, t.effective_to, t.is_active
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


-- =====================================================================
-- COMPREHENSIVE RATE FORMULA + FACTORS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_ComprehensiveRateFormula_SetRate
-- Same insert-only history pattern as TPO pricing.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateFormula_SetRate $$
CREATE PROCEDURE usp_ComprehensiveRateFormula_SetRate (
    IN  p_underwriter_id    BIGINT UNSIGNED,
    IN  p_vehicle_class_id   BIGINT UNSIGNED,
    IN  p_base_rate_percent   DECIMAL(5,2),
    IN  p_min_premium           DECIMAL(18,2),
    IN  p_effective_from           DATE,
    IN  p_actor_id                    BIGINT UNSIGNED,
    OUT o_result_code                   INT,
    OUT o_result_message                  VARCHAR(500),
    OUT o_formula_id                        BIGINT UNSIGNED
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

    IF p_underwriter_id IS NULL OR p_vehicle_class_id IS NULL
       OR p_base_rate_percent IS NULL OR p_min_premium IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, vehicle_class_id, base_rate_percent and min_premium are required.';
        LEAVE proc_label;
    END IF;

    IF p_base_rate_percent <= 0 OR p_min_premium < 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'base_rate_percent must be > 0 and min_premium must be >= 0.';
        LEAVE proc_label;
    END IF;

    IF p_effective_from IS NULL THEN
        SET p_effective_from = CURDATE();
    END IF;

    START TRANSACTION;

    SELECT formula_id INTO v_old_id
    FROM ComprehensiveRateFormula
    WHERE underwriter_id = p_underwriter_id
      AND vehicle_class_id = p_vehicle_class_id
      AND is_active = 1
    LIMIT 1
    FOR UPDATE;

    IF v_old_id IS NOT NULL THEN
        UPDATE ComprehensiveRateFormula
        SET is_active = 0, effective_to = DATE_SUB(p_effective_from, INTERVAL 1 DAY)
        WHERE formula_id = v_old_id;
    END IF;

    INSERT INTO ComprehensiveRateFormula (underwriter_id, vehicle_class_id, base_rate_percent,
                                           min_premium, effective_from, effective_to, is_active)
    VALUES (p_underwriter_id, p_vehicle_class_id, p_base_rate_percent, p_min_premium,
            p_effective_from, NULL, 1);

    SET o_formula_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'ComprehensiveRateFormula', o_formula_id,
            IF(v_old_id IS NOT NULL, JSON_OBJECT('superseded_formula_id', v_old_id), NULL),
            JSON_OBJECT('underwriter_id', p_underwriter_id, 'vehicle_class_id', p_vehicle_class_id,
                        'base_rate_percent', p_base_rate_percent, 'min_premium', p_min_premium),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ComprehensiveRateFactor_Add
-- Adds a loading/discount factor to an existing formula (e.g. anti-theft
-- discount, no-claims bonus). Factors are additive line items, not
-- history-tracked individually — to change one, remove and re-add, or
-- set a new formula version via usp_ComprehensiveRateFormula_SetRate
-- (which starts fresh and needs its own factors re-added).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateFactor_Add $$
CREATE PROCEDURE usp_ComprehensiveRateFactor_Add (
    IN  p_formula_id      BIGINT UNSIGNED,
    IN  p_factor_type     VARCHAR(50),
    IN  p_factor_percent  DECIMAL(5,2),
    IN  p_actor_id        BIGINT UNSIGNED,
    OUT o_result_code     INT,
    OUT o_result_message  VARCHAR(500),
    OUT o_factor_id       BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_formula_id IS NULL OR p_factor_type IS NULL OR p_factor_percent IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'formula_id, factor_type and factor_percent are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ComprehensiveRateFormula WHERE formula_id = p_formula_id AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active formula not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO ComprehensiveRateFactors (formula_id, factor_type, factor_percent)
    VALUES (p_formula_id, p_factor_type, p_factor_percent);

    SET o_factor_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'ComprehensiveRateFactors', o_factor_id,
            NULL, JSON_OBJECT('formula_id', p_formula_id, 'factor_type', p_factor_type, 'factor_percent', p_factor_percent),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_ComprehensiveRateFactor_GetListByFormula $$
CREATE PROCEDURE usp_ComprehensiveRateFactor_GetListByFormula (
    IN  p_formula_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_formula_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'formula_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT factor_id, formula_id, factor_type, factor_percent
    FROM ComprehensiveRateFactors
    WHERE formula_id = p_formula_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ComprehensiveRateFormula_CalculatePremium
-- The core Comprehensive pricing calculation called by the quote/purchase
-- flow: finds the active formula for underwriter+vehicle_class, sums its
-- factors (loadings/discounts) on top of the base rate, applies that
-- effective rate to vehicle_value, and floors the result at min_premium.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateFormula_CalculatePremium $$
CREATE PROCEDURE usp_ComprehensiveRateFormula_CalculatePremium (
    IN  p_underwriter_id   BIGINT UNSIGNED,
    IN  p_vehicle_class_id BIGINT UNSIGNED,
    IN  p_vehicle_value    DECIMAL(18,2),
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500),
    OUT o_formula_id       BIGINT UNSIGNED,
    OUT o_effective_rate_percent DECIMAL(6,2),
    OUT o_premium          DECIMAL(18,2)
)
proc_label: BEGIN
    DECLARE v_base_rate DECIMAL(5,2);
    DECLARE v_min_premium DECIMAL(18,2);
    DECLARE v_factor_total DECIMAL(6,2);
    DECLARE v_calculated DECIMAL(18,2);

    IF p_underwriter_id IS NULL OR p_vehicle_class_id IS NULL OR p_vehicle_value IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, vehicle_class_id and vehicle_value are required.';
        LEAVE proc_label;
    END IF;

    IF p_vehicle_value <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_value must be greater than zero.';
        LEAVE proc_label;
    END IF;

    SELECT formula_id, base_rate_percent, min_premium
    INTO o_formula_id, v_base_rate, v_min_premium
    FROM ComprehensiveRateFormula
    WHERE underwriter_id = p_underwriter_id
      AND vehicle_class_id = p_vehicle_class_id
      AND is_active = 1
      AND effective_from <= CURDATE()
      AND (effective_to IS NULL OR effective_to >= CURDATE())
    ORDER BY effective_from DESC
    LIMIT 1;

    IF o_formula_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'No active Comprehensive rate formula configured for this underwriter/vehicle class.';
        LEAVE proc_label;
    END IF;

    SELECT COALESCE(SUM(factor_percent), 0) INTO v_factor_total
    FROM ComprehensiveRateFactors
    WHERE formula_id = o_formula_id;

    SET o_effective_rate_percent = v_base_rate + v_factor_total;
    SET v_calculated = p_vehicle_value * o_effective_rate_percent / 100;
    SET o_premium = GREATEST(v_calculated, v_min_premium);

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
