-- =====================================================================
-- medical_individual_fields_migration.sql
-- Reshapes QuoteRequestMedicalIndividual to the confirmed field list:
--   1. Customer Information : id_no, first_name, last_name, other_names,
--                             email, mobile_number
--   2. Coverage Details     : inpatient_limit
--   3. Optional Benefits    : outpatient yes/no + limit, dental yes/no +
--                             limit, maternity yes/no (no limit)
-- family_members_json keeps its existing {relationship, fullName,
-- dateOfBirth} shape unchanged.
--
-- Quote requests are now WEBSITE-only: usp_QuoteRequestMedicalIndividual_Create
-- no longer takes a p_channel parameter and hardcodes 'WEBSITE' (the
-- QuoteRequests.channel CHECK constraint already allows it).
--
-- SAFE TO RERUN only on an empty table - client_name/client_dob data is
-- DROPPED. (Table was emptied before this migration on 2026-08-24.)
-- Replaces both Medical Individual procs; run with DELIMITER support
-- (mysql CLI / Workbench).
-- =====================================================================

USE insurance_platform;

ALTER TABLE QuoteRequestMedicalIndividual
    ADD COLUMN first_name        VARCHAR(80)   NOT NULL AFTER quote_request_id,
    ADD COLUMN last_name         VARCHAR(80)   NOT NULL AFTER first_name,
    ADD COLUMN other_names       VARCHAR(150)  NULL     AFTER last_name,
    ADD COLUMN inpatient_limit   DECIMAL(18,2) NOT NULL AFTER id_no,
    ADD COLUMN has_outpatient    TINYINT(1)    NOT NULL DEFAULT 0 AFTER inpatient_limit,
    ADD COLUMN outpatient_limit  DECIMAL(18,2) NULL     AFTER has_outpatient,
    ADD COLUMN has_dental        TINYINT(1)    NOT NULL DEFAULT 0 AFTER outpatient_limit,
    ADD COLUMN dental_limit      DECIMAL(18,2) NULL     AFTER has_dental,
    ADD COLUMN has_maternity     TINYINT(1)    NOT NULL DEFAULT 0 AFTER dental_limit,
    DROP COLUMN client_name,
    DROP COLUMN client_dob,
    RENAME COLUMN phone TO mobile_number,
    -- Some databases predate the require-idno-email migration and still have
    -- email nullable - align it here (safe on an empty table).
    MODIFY COLUMN email VARCHAR(150) NOT NULL;

DELIMITER $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestMedicalIndividual_Create $$
CREATE PROCEDURE usp_QuoteRequestMedicalIndividual_Create (
    IN  p_client_id             BIGINT UNSIGNED,
    IN  p_requested_by_user_id  BIGINT UNSIGNED,
    IN  p_id_no                 VARCHAR(50),
    IN  p_first_name            VARCHAR(80),
    IN  p_last_name             VARCHAR(80),
    IN  p_other_names           VARCHAR(150),
    IN  p_email                 VARCHAR(150),
    IN  p_mobile_number         VARCHAR(20),
    IN  p_inpatient_limit       DECIMAL(18,2),
    IN  p_has_outpatient        TINYINT(1),
    IN  p_outpatient_limit      DECIMAL(18,2),
    IN  p_has_dental            TINYINT(1),
    IN  p_dental_limit          DECIMAL(18,2),
    IN  p_has_maternity         TINYINT(1),
    IN  p_family_members_json   JSON,
    IN  p_actor_type            VARCHAR(20),
    IN  p_actor_id              BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_quote_request_id      BIGINT UNSIGNED,
    OUT o_ref_no                VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;
    -- Short, external-facing tracking code (e.g. "MI-7F3K2A") - NOT the
    -- primary key, which stays quote_request_id/o_quote_request_id
    -- untouched for every internal FK/join.
    DECLARE v_ref_no VARCHAR(20);
    DECLARE v_attempts INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_first_name IS NULL OR p_last_name IS NULL OR p_id_no IS NULL
       OR p_email IS NULL OR p_mobile_number IS NULL OR p_inpatient_limit IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'first_name, last_name, id_no, email, mobile_number and inpatient_limit are required.';
        LEAVE proc_label;
    END IF;

    IF p_has_outpatient = 1 AND p_outpatient_limit IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'outpatient_limit is required when the Outpatient benefit is enabled.';
        LEAVE proc_label;
    END IF;

    IF p_has_dental = 1 AND p_dental_limit IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'dental_limit is required when the Dental benefit is enabled.';
        LEAVE proc_label;
    END IF;

    SELECT product_id INTO v_product_id FROM Products WHERE code = 'MED_IND';

    REPEAT
        SET v_ref_no = CONCAT('MI-', UPPER(SUBSTRING(MD5(RAND()), 1, 6)));
        SET v_attempts = v_attempts + 1;
    UNTIL NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE ref_no = v_ref_no) OR v_attempts >= 5
    END REPEAT;

    START TRANSACTION;

    -- Channel is hardcoded: quote requests can only be made from the website now.
    INSERT INTO QuoteRequests (product_id, client_id, requested_by_user_id, channel, status, ref_no, created_on)
    VALUES (v_product_id, p_client_id, p_requested_by_user_id, 'WEBSITE', 'PENDING', v_ref_no, NOW());

    SET o_quote_request_id = LAST_INSERT_ID();
    SET o_ref_no = v_ref_no;

    INSERT INTO QuoteRequestMedicalIndividual (quote_request_id, first_name, last_name, other_names,
                                                family_members_json, id_no, email, mobile_number,
                                                inpatient_limit, has_outpatient, outpatient_limit,
                                                has_dental, dental_limit, has_maternity)
    VALUES (o_quote_request_id, p_first_name, p_last_name, p_other_names,
            p_family_members_json, p_id_no, p_email, p_mobile_number,
            p_inpatient_limit, COALESCE(p_has_outpatient, 0), p_outpatient_limit,
            COALESCE(p_has_dental, 0), p_dental_limit, COALESCE(p_has_maternity, 0));

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_quote_request_id), 'CREATE', 'QuoteRequests', o_quote_request_id,
            NULL, JSON_OBJECT('product', 'MED_IND', 'first_name', p_first_name, 'last_name', p_last_name), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestMedicalIndividual_GetDetail $$
CREATE PROCEDURE usp_QuoteRequestMedicalIndividual_GetDetail (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT * FROM QuoteRequestMedicalIndividual WHERE quote_request_id = p_quote_request_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
