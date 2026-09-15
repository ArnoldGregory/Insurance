-- ================================================================
-- Comprehensive Insurance Pricing — Migration
-- ================================================================
-- Adds:
--   1. Missing underwriters from the Excel rate sheet
--   2. ComprehensiveRateBand — value-based rate bands per underwriter
--   3. ComprehensiveBenefit — optional benefits per underwriter
--   4. Stored procs for compare + benefits
-- ================================================================

-- 1. ADD MISSING UNDERWRITERS
-- ================================================================
-- Monarch (ID 3) already exists. Add the rest.
INSERT INTO Underwriters (name, code, is_active, created_on) VALUES
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

-- 3. SEED RATE BANDS (from the Excel)
-- ================================================================

-- Monarch (underwriter_id = 3)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (3, 500000, 1499000, 7.00, 37500, CURDATE()),
  (3, 1500000, 2500000, 4.00, 37500, CURDATE()),
  (3, 2500001, 3500000, 3.00, 37500, CURDATE()),
  (3, 3500001, 999999999, 3.00, 37500, CURDATE());

-- MUA (underwriter_id = 9)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (9, 500000, 2000000, 5.00, 45000, CURDATE()),
  (9, 2000001, 4000000, 3.50, 45000, CURDATE()),
  (9, 4000001, 999999999, 3.00, 45000, CURDATE());

-- Heritage (underwriter_id = 10)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (10, 500000, 1000000, 7.00, 50000, CURDATE()),
  (10, 1000001, 1500000, 5.00, 70000, CURDATE()),
  (10, 1500001, 2500000, 3.50, 71000, CURDATE()),
  (10, 2500001, 3000000, 3.00, 87500, CURDATE()),
  (10, 3000001, 999999999, 2.75, 87500, CURDATE());

-- Pacis (underwriter_id = 11)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (11, 500000, 1499000, 7.00, 37500, CURDATE()),
  (11, 1500000, 2499999, 4.00, 37500, CURDATE()),
  (11, 2500000, 999999999, 3.00, 37500, CURDATE());

-- Old Mutual (underwriter_id = 12)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (12, 500000, 1000000, 6.00, 37500, CURDATE()),
  (12, 1000001, 1500000, 5.00, 37500, CURDATE()),
  (12, 1500001, 2999999, 4.00, 37500, CURDATE()),
  (12, 3500001, 999999999, 3.00, 37500, CURDATE());

-- Kenindia (underwriter_id = 13)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (13, 500000, 1000000, 6.00, 37500, CURDATE()),
  (13, 1000001, 1500000, 5.00, 60000, CURDATE()),
  (13, 1500001, 2500000, 4.00, 75000, CURDATE()),
  (13, 2500001, 5000000, 3.50, 100000, CURDATE()),
  (13, 5000001, 999999999, 3.00, 175000, CURDATE());

-- Kenya Orient (underwriter_id = 14)
INSERT INTO ComprehensiveRateBand (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from) VALUES
  (14, 500000, 1000000, 6.00, 35000, CURDATE()),
  (14, 1000001, 2000000, 4.00, 35000, CURDATE()),
  (14, 2000001, 999999999, 3.00, 35000, CURDATE());

-- 4. SEED OPTIONAL BENEFITS (same set for all underwriters)
-- ================================================================

-- Standard optional benefits for ALL underwriters
INSERT INTO ComprehensiveBenefit (underwriter_id, benefit_code, benefit_name, default_price, is_included_in_base, description) VALUES
-- Monarch
  (3, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (3, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (3, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (3, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (3, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (3, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- MUA
  (9, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (9, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (9, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (9, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (9, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (9, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- Heritage
  (10, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (10, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (10, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (10, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (10, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (10, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- Pacis
  (11, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (11, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (11, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (11, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (11, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (11, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- Old Mutual
  (12, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (12, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (12, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (12, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (12, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (12, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- Kenindia
  (13, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (13, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (13, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (13, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (13, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (13, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers'),

-- Kenya Orient
  (14, 'EXCESS_PROTECTOR', 'Excess Protector', 8000, 0, 'Covers the excess/deductible on accidental damage claims'),
  (14, 'COURTESY_CAR', 'Courtesy Car', 3000, 0, 'KES 3,000 for 10 days, max 30 days. Excess 3 days.'),
  (14, 'DRIVERS_PA', 'Drivers Personal Accident', 1000, 0, 'Death and PTD limit KES 250,000'),
  (14, 'AA_ROAD_RESCUE', 'AA Road Rescue', 6500, 0, '24/7 roadside assistance'),
  (14, 'TPPD_UPGRADE', 'TPPD Upgrade', 7500, 0, 'Third Party Property Damage upgrade'),
  (14, 'YOUNG_NOVICE', 'Young/Novice Driver Cover', 5000, 0, 'Additional cover for young/novice drivers');

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
