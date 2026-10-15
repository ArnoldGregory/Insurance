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
