-- ================================================================
-- Comprehensive Insurance Pricing — Migration
-- ================================================================
-- Adds:
--   1. Underwriters needed for comprehensive rate bands (fresh-safe:
--      underwriters are inserted by name/code and all IDs are resolved
--      via SELECT, so this file no longer depends on a pre-existing
--      legacy roster with fixed numeric IDs).
--   2. ComprehensiveRateBand — value-based rate bands per underwriter
--   3. ComprehensiveBenefit — optional benefits per underwriter
--   4. Stored procs for compare + benefits
-- ================================================================

-- 1. ENSURE UNDERWRITERS EXIST
-- ================================================================
INSERT INTO Underwriters (name, code, is_active, created_on) VALUES
  ('Monarch Insurance', 'MONARCH', 1, NOW()),
  ('MUA Insurance', 'MUA', 1, NOW()),
  ('Heritage Insurance', 'HERITAGE', 1, NOW()),
  ('Pacis Insurance', 'PACIS', 1, NOW()),
  ('Old Mutual Insurance', 'OLDMUTUAL', 1, NOW()),
  ('Kenindia Insurance', 'KENINDIA', 1, NOW()),
  ('Kenya Orient Insurance', 'KENYA_ORIENT', 1, NOW())
ON DUPLICATE KEY UPDATE name = name;

-- 2. CREATE TABLES
-- ================================================================

CREATE TABLE IF NOT EXISTS ComprehensiveRateBand (
    band_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id    BIGINT UNSIGNED NOT NULL,
    value_min         DECIMAL(18,2) NOT NULL,
    value_max         DECIMAL(18,2) NOT NULL,
    rate_percent      DECIMAL(7,4) NOT NULL COMMENT 'e.g. 3.50 = 3.5%',
    min_premium       DECIMAL(18,2) NOT NULL DEFAULT 0,
    effective_from    DATE NOT NULL,
    effective_to      DATE NULL,
    is_active         TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_rb_underwriter FOREIGN KEY (underwriter_id) REFERENCES Underwriters(underwriter_id) ON DELETE RESTRICT,
    INDEX idx_rb_lookup (underwriter_id, is_active, value_min, value_max)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS ComprehensiveBenefit (
    benefit_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id    BIGINT UNSIGNED NOT NULL,
    benefit_code      VARCHAR(50) NOT NULL,
    benefit_name      VARCHAR(150) NOT NULL,
    default_price     DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT '0 = included in base',
    is_included_in_base TINYINT(1) NOT NULL DEFAULT 0,
    description       VARCHAR(500) NULL,
    is_active         TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_ben_underwriter FOREIGN KEY (underwriter_id) REFERENCES Underwriters(underwriter_id) ON DELETE RESTRICT,
    INDEX idx_ben_lookup (underwriter_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. SEED RATE BANDS (from the Excel, by underwriter code so the
--    seeding is independent of numeric auto-increment IDs)
-- ================================================================

DELETE FROM ComprehensiveRateBand;

INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from)
SELECT u.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, CURDATE()
FROM Underwriters u
JOIN (
    VALUES ROW('MONARCH', 500000, 1499000, 7.00, 37500),
           ROW('MONARCH', 1500000, 2500000, 4.00, 37500),
           ROW('MONARCH', 2500001, 3500000, 3.00, 37500),
           ROW('MONARCH', 3500001, 999999999, 3.00, 37500),
           ROW('MUA', 500000, 2000000, 5.00, 45000),
           ROW('MUA', 2000001, 4000000, 3.50, 45000),
           ROW('MUA', 4000001, 999999999, 3.00, 45000),
           ROW('HERITAGE', 500000, 1000000, 7.00, 50000),
           ROW('HERITAGE', 1000001, 1500000, 5.00, 70000),
           ROW('HERITAGE', 1500001, 2500000, 3.50, 71000),
           ROW('HERITAGE', 2500001, 3000000, 3.00, 87500),
           ROW('HERITAGE', 3000001, 999999999, 2.75, 87500),
           ROW('PACIS', 500000, 1499000, 7.00, 37500),
           ROW('PACIS', 1500000, 2499999, 4.00, 37500),
           ROW('PACIS', 2500000, 999999999, 3.00, 37500),
           ROW('OLDMUTUAL', 500000, 1000000, 6.00, 37500),
           ROW('OLDMUTUAL', 1000001, 1500000, 5.00, 37500),
           ROW('OLDMUTUAL', 1500001, 2999999, 4.00, 37500),
           ROW('OLDMUTUAL', 3500001, 999999999, 3.00, 37500),
           ROW('KENINDIA', 500000, 1000000, 6.00, 37500),
           ROW('KENINDIA', 1000001, 1500000, 5.00, 60000),
           ROW('KENINDIA', 1500001, 2500000, 4.00, 75000),
           ROW('KENINDIA', 2500001, 5000000, 3.50, 100000),
           ROW('KENINDIA', 5000001, 999999999, 3.00, 175000),
           ROW('KENYA_ORIENT', 500000, 1000000, 6.00, 35000),
           ROW('KENYA_ORIENT', 1000001, 2000000, 4.00, 35000),
           ROW('KENYA_ORIENT', 2000001, 999999999, 3.00, 35000)
) AS b(uw_code, value_min, value_max, rate_percent, min_premium)
  ON b.uw_code = u.code
WHERE u.code IN ('MONARCH','MUA','HERITAGE','PACIS','OLDMUTUAL','KENINDIA','KENYA_ORIENT');

-- 4. SEED OPTIONAL BENEFITS (same set for all underwriters)
-- ================================================================

DELETE FROM ComprehensiveBenefit;

INSERT INTO ComprehensiveBenefit (underwriter_id, benefit_code, benefit_name, default_price, is_included_in_base, description)
SELECT u.underwriter_id, b.benefit_code, b.benefit_name, b.default_price, b.is_included_in_base, b.description
FROM Underwriters u
JOIN (
    VALUES ROW('EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
           ROW('COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
           ROW('DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
           ROW('AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
           ROW('TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
           ROW('YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers')
) AS b(benefit_code, benefit_name, default_price, is_included_in_base, description) ON 1=1
WHERE u.code IN ('MONARCH','MUA','HERITAGE','PACIS','OLDMUTUAL','KENINDIA','KENYA_ORIENT');

-- 5. STORED PROCEDURES
-- ================================================================

DROP PROCEDURE IF EXISTS usp_ComprehensiveRateBand_GetOptions;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveRateBand_GetOptions(
    IN p_vehicle_value DECIMAL(18,2),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SET o_result_code = 0;
    SET o_result_message = 'Success';

    SELECT
        u.underwriter_id,
        u.name AS underwriter_name,
        rb.rate_percent,
        rb.min_premium,
        rb.value_min,
        rb.value_max,
        ROUND(p_vehicle_value * rb.rate_percent / 100, 2) AS base_premium,
        ROUND(GREATEST(p_vehicle_value * 0.0025, 2500), 2) AS pvt_amount,
        ROUND(ROUND(p_vehicle_value * rb.rate_percent / 100, 2) + ROUND(GREATEST(p_vehicle_value * 0.0025, 2500), 2), 2) AS total_premium
    FROM ComprehensiveRateBand rb
    INNER JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
    WHERE rb.is_active = 1
      AND u.is_active = 1
      AND p_vehicle_value >= rb.value_min
      AND p_vehicle_value <= rb.value_max
    ORDER BY total_premium ASC;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS usp_ComprehensiveBenefit_GetList;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveBenefit_GetList(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SET o_result_code = 0;
    SET o_result_message = 'Success';

    SELECT
        benefit_id,
        benefit_code,
        benefit_name,
        default_price,
        is_included_in_base,
        description
    FROM ComprehensiveBenefit
    WHERE underwriter_id = p_underwriter_id
      AND is_active = 1
    ORDER BY is_included_in_base DESC, benefit_name ASC;
END //
DELIMITER ;