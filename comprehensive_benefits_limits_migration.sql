-- ================================================================
-- Comprehensive Benefits & Liability Limits — Migration
-- ================================================================
-- Adds:
--   1. display_order column to ComprehensiveBenefit
--   2. ComprehensiveLiabilityLimit — liability limits per underwriter
--   3. Stored procs: LiabilityLimit CRUD, Benefit Upsert/Delete,
--      RateBand Upsert/Delete
--   4. Seed liability limits for all 7 underwriters
--   5. Seed additional benefits (Extra Windscreen, Extra Radio Cassette)
-- ================================================================

USE insurance_platform;

-- ================================================================
-- 1. ALTER ComprehensiveBenefit — add display_order column
-- ================================================================

-- Add display_order for sorting benefits in the UI
ALTER TABLE ComprehensiveBenefit
    ADD COLUMN display_order INT NOT NULL DEFAULT 0 AFTER is_included_in_base;

-- Unique constraint so INSERT IGNORE seeding is idempotent
ALTER TABLE ComprehensiveBenefit
    ADD UNIQUE INDEX uq_ben_uw_code (underwriter_id, benefit_code);

-- ================================================================
-- 2. CREATE ComprehensiveLiabilityLimit TABLE
-- ================================================================

CREATE TABLE IF NOT EXISTS ComprehensiveLiabilityLimit (
    liability_limit_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id      BIGINT UNSIGNED NOT NULL,
    limit_name          VARCHAR(200) NOT NULL,
    limit_value         VARCHAR(500) NOT NULL,
    display_order       INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_ll_underwriter FOREIGN KEY (underwriter_id) REFERENCES Underwriters(underwriter_id) ON DELETE RESTRICT,
    INDEX idx_ll_lookup (underwriter_id, display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ================================================================
-- 3. STORED PROCEDURES
-- ================================================================

-- ----------------------------------------------------------------
-- usp_ComprehensiveLiabilityLimit_GetByUnderwriter
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveLiabilityLimit_GetByUnderwriter;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveLiabilityLimit_GetByUnderwriter(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT liability_limit_id, underwriter_id, limit_name, limit_value, display_order
    FROM ComprehensiveLiabilityLimit
    WHERE underwriter_id = p_underwriter_id
    ORDER BY display_order ASC, limit_name ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveLiabilityLimit_Upsert
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveLiabilityLimit_Upsert;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveLiabilityLimit_Upsert(
    IN p_liability_limit_id BIGINT UNSIGNED,
    IN p_underwriter_id     BIGINT UNSIGNED,
    IN p_limit_name         VARCHAR(200),
    IN p_limit_value        VARCHAR(500),
    IN p_display_order      INT,
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_existing_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_limit_name IS NULL OR p_limit_value IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, limit_name and limit_value are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    IF p_display_order IS NULL THEN
        SET p_display_order = 0;
    END IF;

    START TRANSACTION;

    IF p_liability_limit_id IS NULL OR p_liability_limit_id = 0 THEN
        INSERT INTO ComprehensiveLiabilityLimit (underwriter_id, limit_name, limit_value, display_order)
        VALUES (p_underwriter_id, p_limit_name, p_limit_value, p_display_order);
    ELSE
        SELECT liability_limit_id INTO v_existing_id
        FROM ComprehensiveLiabilityLimit
        WHERE liability_limit_id = p_liability_limit_id;

        IF v_existing_id IS NULL THEN
            ROLLBACK;
            SET o_result_code = 2;
            SET o_result_message = 'Liability limit not found.';
            LEAVE proc_label;
        END IF;

        UPDATE ComprehensiveLiabilityLimit
        SET underwriter_id = p_underwriter_id,
            limit_name     = p_limit_name,
            limit_value    = p_limit_value,
            display_order  = p_display_order
        WHERE liability_limit_id = p_liability_limit_id;
    END IF;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveLiabilityLimit_Delete
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveLiabilityLimit_Delete;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveLiabilityLimit_Delete(
    IN p_liability_limit_id BIGINT UNSIGNED,
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_liability_limit_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'liability_limit_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ComprehensiveLiabilityLimit WHERE liability_limit_id = p_liability_limit_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Liability limit not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    DELETE FROM ComprehensiveLiabilityLimit
    WHERE liability_limit_id = p_liability_limit_id;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveBenefit_Upsert
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveBenefit_Upsert;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveBenefit_Upsert(
    IN p_benefit_id          BIGINT UNSIGNED,
    IN p_underwriter_id      BIGINT UNSIGNED,
    IN p_benefit_code        VARCHAR(50),
    IN p_benefit_name        VARCHAR(200),
    IN p_default_price       DECIMAL(18,2),
    IN p_is_included_in_base TINYINT(1),
    IN p_description         TEXT,
    IN p_display_order       INT,
    OUT o_result_code        INT,
    OUT o_result_message     VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_existing_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_benefit_code IS NULL OR p_benefit_name IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, benefit_code and benefit_name are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    IF p_default_price IS NULL THEN
        SET p_default_price = 0;
    END IF;

    IF p_is_included_in_base IS NULL THEN
        SET p_is_included_in_base = 0;
    END IF;

    IF p_display_order IS NULL THEN
        SET p_display_order = 0;
    END IF;

    START TRANSACTION;

    IF p_benefit_id IS NULL OR p_benefit_id = 0 THEN
        INSERT INTO ComprehensiveBenefit (underwriter_id, benefit_code, benefit_name,
                                           default_price, is_included_in_base, description, display_order)
        VALUES (p_underwriter_id, p_benefit_code, p_benefit_name,
                p_default_price, p_is_included_in_base, p_description, p_display_order);
    ELSE
        SELECT benefit_id INTO v_existing_id
        FROM ComprehensiveBenefit
        WHERE benefit_id = p_benefit_id;

        IF v_existing_id IS NULL THEN
            ROLLBACK;
            SET o_result_code = 2;
            SET o_result_message = 'Benefit not found.';
            LEAVE proc_label;
        END IF;

        UPDATE ComprehensiveBenefit
        SET underwriter_id      = p_underwriter_id,
            benefit_code        = p_benefit_code,
            benefit_name        = p_benefit_name,
            default_price       = p_default_price,
            is_included_in_base = p_is_included_in_base,
            description         = p_description,
            display_order       = p_display_order
        WHERE benefit_id = p_benefit_id;
    END IF;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveBenefit_Delete
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveBenefit_Delete;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveBenefit_Delete(
    IN p_benefit_id       BIGINT UNSIGNED,
    OUT o_result_code     INT,
    OUT o_result_message  VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_benefit_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'benefit_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ComprehensiveBenefit WHERE benefit_id = p_benefit_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Benefit not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    DELETE FROM ComprehensiveBenefit
    WHERE benefit_id = p_benefit_id;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveRateBand_Upsert
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateBand_Upsert;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveRateBand_Upsert(
    IN p_rate_band_id    BIGINT UNSIGNED,
    IN p_underwriter_id  BIGINT UNSIGNED,
    IN p_min_value       DECIMAL(18,2),
    IN p_max_value       DECIMAL(18,2),
    IN p_rate_percent    DECIMAL(10,4),
    IN p_min_premium     DECIMAL(18,2),
    IN p_display_order   INT,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_existing_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_underwriter_id IS NULL OR p_min_value IS NULL OR p_max_value IS NULL
       OR p_rate_percent IS NULL OR p_min_premium IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'underwriter_id, value_min, value_max, rate_percent and min_premium are required.';
        LEAVE proc_label;
    END IF;

    IF p_min_value >= p_max_value THEN
        SET o_result_code = 1;
        SET o_result_message = 'value_min must be less than value_max.';
        LEAVE proc_label;
    END IF;

    IF p_rate_percent <= 0 OR p_min_premium < 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'rate_percent must be > 0 and min_premium must be >= 0.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found.';
        LEAVE proc_label;
    END IF;

    IF p_display_order IS NULL THEN
        SET p_display_order = 0;
    END IF;

    START TRANSACTION;

    IF p_rate_band_id IS NULL OR p_rate_band_id = 0 THEN
        INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max,
                                            rate_percent, min_premium, effective_from, is_active)
        VALUES (p_underwriter_id, p_min_value, p_max_value,
                p_rate_percent, p_min_premium, CURDATE(), 1);
    ELSE
        SELECT band_id INTO v_existing_id
        FROM ComprehensiveRateBand
        WHERE band_id = p_rate_band_id;

        IF v_existing_id IS NULL THEN
            ROLLBACK;
            SET o_result_code = 2;
            SET o_result_message = 'Rate band not found.';
            LEAVE proc_label;
        END IF;

        UPDATE ComprehensiveRateBand
        SET underwriter_id = p_underwriter_id,
            value_min      = p_min_value,
            value_max      = p_max_value,
            rate_percent   = p_rate_percent,
            min_premium    = p_min_premium
        WHERE band_id = p_rate_band_id;
    END IF;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

-- ----------------------------------------------------------------
-- usp_ComprehensiveRateBand_Delete
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateBand_Delete;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveRateBand_Delete(
    IN p_rate_band_id    BIGINT UNSIGNED,
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

    IF p_rate_band_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'rate_band_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ComprehensiveRateBand WHERE band_id = p_rate_band_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Rate band not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    DELETE FROM ComprehensiveRateBand
    WHERE band_id = p_rate_band_id;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END //
DELIMITER ;

DELIMITER ;

-- ================================================================
-- 4. SEED LIABILITY LIMITS — same set for all 7 underwriters
-- ================================================================
-- Monarch (3), MUA (9), Heritage (10), Pacis (11),
-- Old Mutual (12), Kenindia (13), Kenya Orient (14)

INSERT IGNORE INTO ComprehensiveLiabilityLimit (underwriter_id, limit_name, limit_value, display_order) VALUES
-- Monarch
  (3,  'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (3,  'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (3,  'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (3,  'Authorized Towing',                     'Kshs.30,000', 4),
  (3,  'Authorized Repair',                     'Kshs.30,000', 5),
  (3,  'Medical Expenses',                      'Kshs.30,000', 6),
  (3,  'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (3,  'Windscreen Limit',                      'Kshs.30,000', 8),
  (3,  'Radio Cassette',                        'Kshs.30,000', 9),

-- MUA
  (9,  'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (9,  'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (9,  'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (9,  'Authorized Towing',                     'Kshs.30,000', 4),
  (9,  'Authorized Repair',                     'Kshs.30,000', 5),
  (9,  'Medical Expenses',                      'Kshs.30,000', 6),
  (9,  'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (9,  'Windscreen Limit',                      'Kshs.30,000', 8),
  (9,  'Radio Cassette',                        'Kshs.30,000', 9),

-- Heritage
  (10, 'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (10, 'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (10, 'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (10, 'Authorized Towing',                     'Kshs.30,000', 4),
  (10, 'Authorized Repair',                     'Kshs.30,000', 5),
  (10, 'Medical Expenses',                      'Kshs.30,000', 6),
  (10, 'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (10, 'Windscreen Limit',                      'Kshs.30,000', 8),
  (10, 'Radio Cassette',                        'Kshs.30,000', 9),

-- Pacis
  (11, 'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (11, 'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (11, 'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (11, 'Authorized Towing',                     'Kshs.30,000', 4),
  (11, 'Authorized Repair',                     'Kshs.30,000', 5),
  (11, 'Medical Expenses',                      'Kshs.30,000', 6),
  (11, 'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (11, 'Windscreen Limit',                      'Kshs.30,000', 8),
  (11, 'Radio Cassette',                        'Kshs.30,000', 9),

-- Old Mutual
  (12, 'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (12, 'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (12, 'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (12, 'Authorized Towing',                     'Kshs.30,000', 4),
  (12, 'Authorized Repair',                     'Kshs.30,000', 5),
  (12, 'Medical Expenses',                      'Kshs.30,000', 6),
  (12, 'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (12, 'Windscreen Limit',                      'Kshs.30,000', 8),
  (12, 'Radio Cassette',                        'Kshs.30,000', 9),

-- Kenindia
  (13, 'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (13, 'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (13, 'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (13, 'Authorized Towing',                     'Kshs.30,000', 4),
  (13, 'Authorized Repair',                     'Kshs.30,000', 5),
  (13, 'Medical Expenses',                      'Kshs.30,000', 6),
  (13, 'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (13, 'Windscreen Limit',                      'Kshs.30,000', 8),
  (13, 'Radio Cassette',                        'Kshs.30,000', 9),

-- Kenya Orient
  (14, 'Third Party Property Damage',           'Kshs.5,000,000', 1),
  (14, 'Third Party Persons Injury/Death',      'Kshs.5,000,000', 2),
  (14, 'Passenger Liability',                   'Kshs.3,000,000/20,000,000', 3),
  (14, 'Authorized Towing',                     'Kshs.30,000', 4),
  (14, 'Authorized Repair',                     'Kshs.30,000', 5),
  (14, 'Medical Expenses',                      'Kshs.30,000', 6),
  (14, 'Geographical Area',                     'Kenya/Uganda/Tanzania(Subject to Yellow Card)', 7),
  (14, 'Windscreen Limit',                      'Kshs.30,000', 8),
  (14, 'Radio Cassette',                        'Kshs.30,000', 9);

-- ================================================================
-- 5. SEED ADDITIONAL BENEFITS — new benefits from the Excel
-- ================================================================
-- Uses INSERT IGNORE (unique on underwriter_id + benefit_code) so
-- existing benefits are untouched; only the two new optional benefits
-- are added per underwriter.

INSERT IGNORE INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order) VALUES
-- Monarch
  (3,  'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (3,  'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- MUA
  (9,  'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (9,  'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- Heritage
  (10, 'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (10, 'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- Pacis
  (11, 'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (11, 'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- Old Mutual
  (12, 'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (12, 'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- Kenindia
  (13, 'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (13, 'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8),

-- Kenya Orient
  (14, 'EXTRA_WINDSCREEN',      'Extra Windscreen',           0, 0, '10% of extra limit', 7),
  (14, 'EXTRA_RADIO_CASSETTE',  'Extra Radio Cassette',       0, 0, '10% of extra limit', 8);
