-- =====================================================================
-- Insurance Platform — Production Database Collation Normalization
-- ---------------------------------------------------------------------
-- Brings the production database in line with what local dev already has:
-- everything utf8mb4 / utf8mb4_0900_ai_ci (the MySQL 8.0 default), so the
-- app's `CharacterSet=utf8mb4;` connection string and its stored-procedure
-- comparisons behave identically in both environments.
--
-- Requirements / notes:
--   * MySQL 8.0 ONLY - utf8mb4_0900_ai_ci does not exist on 5.7. If prod
--     is still 5.7, stop here and plan a MySQL upgrade instead.
--   * Idempotent - safe to re-run; already-correct tables are skipped by
--     the verification report.
--   * Run as a user with ALTER rights on insurance_platform.
--     Example:
--       mysql --default-character-set=utf8mb4 -u esbuser -p insurance_platform \
--         < prod_collation_normalization.sql
--   * Run it in a maintenance window - CONVERT TO CHARACTER SET rebuilds
--     each table (and its indexes) and rewrites every character column.
--
-- What it does:
--   1. DB default -> utf8mb4 / utf8mb4_0900_ai_ci.
--   2. Every table -> CONVERT TO CHARACTER SET utf8mb4
--      COLLATE utf8mb4_0900_ai_ci (converts the table AND all of its
--      character columns, dropping any per-column legacy COLLATEs).
--   3. Diagnostics + a final verification report.
-- =====================================================================

SELECT 'MySQL version' AS check_name, VERSION() AS value;
SELECT IF(VERSION() LIKE '8.0%' OR VERSION() LIKE '8.4%' OR VERSION() LIKE '9.%',
           'OK - utf8mb4_0900_ai_ci is available',
           'STOP - production is NOT MySQL 8+, utf8mb4_0900_ai_ci will not work here')
       AS version_check;

SET @db_name = DATABASE();

ALTER DATABASE `insurance_platform`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Convert every table. A short-lived temporary procedure loops through
-- information_schema and runs one dynamic ALTER per table, then drops
-- itself.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_adhoc_collation_normalize;
DELIMITER $$
CREATE PROCEDURE usp_adhoc_collation_normalize()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_table VARCHAR(255);
    DECLARE cur CURSOR FOR
        SELECT TABLE_NAME
          FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_TYPE   = 'BASE TABLE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    tables_loop: LOOP
        FETCH cur INTO v_table;
        IF done THEN
            LEAVE tables_loop;
        END IF;

        SET @stmt = CONCAT(
            'ALTER TABLE `', v_table, '` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci');
        PREPARE s FROM @stmt;
        EXECUTE s;
        DEALLOCATE PREPARE s;
    END LOOP;
    CLOSE cur;
END $$
DELIMITER ;

CALL usp_adhoc_collation_normalize();
DROP PROCEDURE IF EXISTS usp_adhoc_collation_normalize;

-- ---------------------------------------------------------------------
-- Verification report: nothing below this point should list a row.
-- ---------------------------------------------------------------------
SELECT 'Tables NOT yet normalized (must be empty):' AS note;

SELECT TABLE_SCHEMA, TABLE_NAME
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = @db_name
   AND TABLE_COLLATION <> 'utf8mb4_0900_ai_ci';

SELECT 'Columns NOT yet normalized (must be empty):' AS note;

SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLLATION_NAME
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = @db_name
   AND DATA_TYPE IN ('char', 'varchar', 'text', 'tinytext', 'mediumtext', 'longtext',
                     'enum', 'set')
   AND COLLATION_NAME IS NOT NULL
   AND COLLATION_NAME <> 'utf8mb4_0900_ai_ci';

SELECT 'Final DB default:' AS note;
SELECT @@character_set_database AS charset, @@collation_database AS collation;