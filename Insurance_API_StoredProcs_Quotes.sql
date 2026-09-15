-- =====================================================================
-- Insurance Platform — Stored Procedures: QUOTE WORKFLOW (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Covers: Medical Individual/Corporate, Professional Indemnity, Travel,
-- Domestic quote requests (product_id.pricing_method = MANUAL_QUOTE),
-- and QuoteOffers (back-office uploaded underwriter quotes).
-- NOT used for Motor — TPO/Comprehensive are priced directly via the
-- Catalog/Pricing procs, no QuoteRequests row needed.
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- =====================================================================
-- QUOTE REQUESTS — one Create proc per product detail table, since each
-- has different required fields. Each creates the QuoteRequests parent
-- row and its matching detail row in one transaction (they're 1:1).
-- =====================================================================

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
    -- untouched for every internal FK/join. This is purely what gets shown
    -- to users instead of that raw id. Generated here (not in the API
    -- layer) so it's guaranteed unique at the database level via
    -- uq_qr_ref_no - the retry loop below only matters in the
    -- astronomically unlikely case two concurrent inserts roll the same 6
    -- hex characters.
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

DROP PROCEDURE IF EXISTS usp_QuoteRequestMedicalCorporate_Create $$
CREATE PROCEDURE usp_QuoteRequestMedicalCorporate_Create (
    IN  p_client_id             BIGINT UNSIGNED,
    IN  p_requested_by_user_id  BIGINT UNSIGNED,
    IN  p_channel               VARCHAR(20),
    IN  p_id_no                 VARCHAR(50),
    IN  p_company_name          VARCHAR(150),
    IN  p_phone                 VARCHAR(20),
    IN  p_email                 VARCHAR(150),
    IN  p_actor_type            VARCHAR(20),
    IN  p_actor_id              BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_quote_request_id      BIGINT UNSIGNED,
    OUT o_ref_no                VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_ref_no VARCHAR(20);
    DECLARE v_attempts INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_channel IS NULL OR p_id_no IS NULL OR p_company_name IS NULL OR p_phone IS NULL OR p_email IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel, id_no, company_name, phone and email are required.';
        LEAVE proc_label;
    END IF;

    SELECT product_id INTO v_product_id FROM Products WHERE code = 'MED_CORP';

    REPEAT
        SET v_ref_no = CONCAT('MC-', UPPER(SUBSTRING(MD5(RAND()), 1, 6)));
        SET v_attempts = v_attempts + 1;
    UNTIL NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE ref_no = v_ref_no) OR v_attempts >= 5
    END REPEAT;

    START TRANSACTION;

    INSERT INTO QuoteRequests (product_id, client_id, requested_by_user_id, channel, status, ref_no, created_on)
    VALUES (v_product_id, p_client_id, p_requested_by_user_id, p_channel, 'PENDING', v_ref_no, NOW());

    SET o_quote_request_id = LAST_INSERT_ID();
    SET o_ref_no = v_ref_no;

    INSERT INTO QuoteRequestMedicalCorporate (quote_request_id, id_no, company_name, phone, email)
    VALUES (o_quote_request_id, p_id_no, p_company_name, p_phone, p_email);

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_quote_request_id), 'CREATE', 'QuoteRequests', o_quote_request_id,
            NULL, JSON_OBJECT('product', 'MED_CORP', 'company_name', p_company_name), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestProfessionalIndemnity_Create $$
CREATE PROCEDURE usp_QuoteRequestProfessionalIndemnity_Create (
    IN  p_client_id               BIGINT UNSIGNED,
    IN  p_requested_by_user_id    BIGINT UNSIGNED,
    IN  p_channel                 VARCHAR(20),
    IN  p_id_no                   VARCHAR(50),
    IN  p_client_or_company_name  VARCHAR(150),
    IN  p_phone                   VARCHAR(20),
    IN  p_email                   VARCHAR(150),
    IN  p_profession               VARCHAR(100),
    IN  p_actor_type               VARCHAR(20),
    IN  p_actor_id                 BIGINT UNSIGNED,
    OUT o_result_code              INT,
    OUT o_result_message           VARCHAR(500),
    OUT o_quote_request_id         BIGINT UNSIGNED,
    OUT o_ref_no                   VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_ref_no VARCHAR(20);
    DECLARE v_attempts INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_channel IS NULL OR p_id_no IS NULL OR p_client_or_company_name IS NULL OR p_phone IS NULL
       OR p_email IS NULL OR p_profession IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel, id_no, client_or_company_name, phone, email and profession are required.';
        LEAVE proc_label;
    END IF;

    SELECT product_id INTO v_product_id FROM Products WHERE code = 'PI';

    REPEAT
        SET v_ref_no = CONCAT('PI-', UPPER(SUBSTRING(MD5(RAND()), 1, 6)));
        SET v_attempts = v_attempts + 1;
    UNTIL NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE ref_no = v_ref_no) OR v_attempts >= 5
    END REPEAT;

    START TRANSACTION;

    INSERT INTO QuoteRequests (product_id, client_id, requested_by_user_id, channel, status, ref_no, created_on)
    VALUES (v_product_id, p_client_id, p_requested_by_user_id, p_channel, 'PENDING', v_ref_no, NOW());

    SET o_quote_request_id = LAST_INSERT_ID();
    SET o_ref_no = v_ref_no;

    INSERT INTO QuoteRequestProfessionalIndemnity (quote_request_id, id_no, client_or_company_name, phone,
                                                     email, profession, proposal_form_status)
    VALUES (o_quote_request_id, p_id_no, p_client_or_company_name, p_phone, p_email, p_profession, 'REDIRECTED');

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_quote_request_id), 'CREATE', 'QuoteRequests', o_quote_request_id,
            NULL, JSON_OBJECT('product', 'PI', 'profession', p_profession), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestTravel_Create $$
CREATE PROCEDURE usp_QuoteRequestTravel_Create (
    IN  p_client_id              BIGINT UNSIGNED,
    IN  p_requested_by_user_id   BIGINT UNSIGNED,
    IN  p_channel                VARCHAR(20),
    IN  p_id_no                  VARCHAR(50),
    IN  p_email                  VARCHAR(150),
    IN  p_client_name            VARCHAR(150),
    IN  p_dob                    DATE,
    IN  p_kra_pin                VARCHAR(20),
    IN  p_destination             VARCHAR(150),
    IN  p_travel_date_from         DATE,
    IN  p_travel_date_to             DATE,
    IN  p_travelling_with_family        TINYINT(1),
    IN  p_trip_type                        VARCHAR(20),
    IN  p_actor_type                          VARCHAR(20),
    IN  p_actor_id                              BIGINT UNSIGNED,
    OUT o_result_code                             INT,
    OUT o_result_message                            VARCHAR(500),
    OUT o_quote_request_id                            BIGINT UNSIGNED,
    OUT o_ref_no                                        VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_ref_no VARCHAR(20);
    DECLARE v_attempts INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_channel IS NULL OR p_id_no IS NULL OR p_email IS NULL OR p_client_name IS NULL OR p_dob IS NULL OR p_destination IS NULL
       OR p_travel_date_from IS NULL OR p_travel_date_to IS NULL OR p_trip_type IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel, id_no, email, client_name, dob, destination, travel dates and trip_type are required.';
        LEAVE proc_label;
    END IF;

    IF p_trip_type NOT IN ('VACATION','BUSINESS','SPORTS') THEN
        SET o_result_code = 1;
        SET o_result_message = 'trip_type must be VACATION, BUSINESS or SPORTS.';
        LEAVE proc_label;
    END IF;

    IF p_travel_date_to < p_travel_date_from THEN
        SET o_result_code = 1;
        SET o_result_message = 'travel_date_to cannot be before travel_date_from.';
        LEAVE proc_label;
    END IF;

    SELECT product_id INTO v_product_id FROM Products WHERE code = 'TRAVEL';

    REPEAT
        SET v_ref_no = CONCAT('TR-', UPPER(SUBSTRING(MD5(RAND()), 1, 6)));
        SET v_attempts = v_attempts + 1;
    UNTIL NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE ref_no = v_ref_no) OR v_attempts >= 5
    END REPEAT;

    START TRANSACTION;

    INSERT INTO QuoteRequests (product_id, client_id, requested_by_user_id, channel, status, ref_no, created_on)
    VALUES (v_product_id, p_client_id, p_requested_by_user_id, p_channel, 'PENDING', v_ref_no, NOW());

    SET o_quote_request_id = LAST_INSERT_ID();
    SET o_ref_no = v_ref_no;

    INSERT INTO QuoteRequestTravel (quote_request_id, id_no, email, client_name, dob, kra_pin, destination,
                                     travel_date_from, travel_date_to, travelling_with_family, trip_type)
    VALUES (o_quote_request_id, p_id_no, p_email, p_client_name, p_dob, p_kra_pin, p_destination,
            p_travel_date_from, p_travel_date_to, COALESCE(p_travelling_with_family, 0), p_trip_type);

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_quote_request_id), 'CREATE', 'QuoteRequests', o_quote_request_id,
            NULL, JSON_OBJECT('product', 'TRAVEL', 'destination', p_destination), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteRequestDomestic_Create
-- Uses the TEMPORARY details_json placeholder until Domestic Insurance
-- fields are confirmed (see Insurance_API_Schema_Design.md open items).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteRequestDomestic_Create $$
CREATE PROCEDURE usp_QuoteRequestDomestic_Create (
    IN  p_client_id             BIGINT UNSIGNED,
    IN  p_requested_by_user_id  BIGINT UNSIGNED,
    IN  p_channel               VARCHAR(20),
    IN  p_id_no                 VARCHAR(50),
    IN  p_email                 VARCHAR(150),
    IN  p_details_json          JSON,
    IN  p_actor_type            VARCHAR(20),
    IN  p_actor_id              BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_quote_request_id      BIGINT UNSIGNED,
    OUT o_ref_no                VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_ref_no VARCHAR(20);
    DECLARE v_attempts INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_channel IS NULL OR p_id_no IS NULL OR p_email IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel, id_no and email are required.';
        LEAVE proc_label;
    END IF;

    SELECT product_id INTO v_product_id FROM Products WHERE code = 'DOMESTIC';

    REPEAT
        SET v_ref_no = CONCAT('DM-', UPPER(SUBSTRING(MD5(RAND()), 1, 6)));
        SET v_attempts = v_attempts + 1;
    UNTIL NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE ref_no = v_ref_no) OR v_attempts >= 5
    END REPEAT;

    START TRANSACTION;

    INSERT INTO QuoteRequests (product_id, client_id, requested_by_user_id, channel, status, ref_no, created_on)
    VALUES (v_product_id, p_client_id, p_requested_by_user_id, p_channel, 'PENDING', v_ref_no, NOW());

    SET o_quote_request_id = LAST_INSERT_ID();
    SET o_ref_no = v_ref_no;

    INSERT INTO QuoteRequestDomestic (quote_request_id, id_no, email, details_json)
    VALUES (o_quote_request_id, p_id_no, p_email, p_details_json);

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_quote_request_id), 'CREATE', 'QuoteRequests', o_quote_request_id,
            NULL, JSON_OBJECT('product', 'DOMESTIC'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- QUOTE REQUESTS — shared parent-row operations + per-type detail fetch
-- =====================================================================

DROP PROCEDURE IF EXISTS usp_QuoteRequest_GetById $$
CREATE PROCEDURE usp_QuoteRequest_GetById (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_quote_request_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_request_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE quote_request_id = p_quote_request_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Quote request not found.';
        LEAVE proc_label;
    END IF;

    -- The API layer reads product_code from this result to decide which
    -- usp_QuoteRequest<Type>_GetDetail proc to call next.
    SELECT qr.quote_request_id, qr.ref_no, qr.product_id, p.code AS product_code, qr.client_id,
           qr.requested_by_user_id, qr.channel, qr.status, qr.assigned_backoffice_user_id, qr.created_on
    FROM QuoteRequests qr
    JOIN Products p ON p.product_id = qr.product_id
    WHERE qr.quote_request_id = p_quote_request_id;

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

DROP PROCEDURE IF EXISTS usp_QuoteRequestMedicalCorporate_GetDetail $$
CREATE PROCEDURE usp_QuoteRequestMedicalCorporate_GetDetail (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT * FROM QuoteRequestMedicalCorporate WHERE quote_request_id = p_quote_request_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestProfessionalIndemnity_GetDetail $$
CREATE PROCEDURE usp_QuoteRequestProfessionalIndemnity_GetDetail (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT * FROM QuoteRequestProfessionalIndemnity WHERE quote_request_id = p_quote_request_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestTravel_GetDetail $$
CREATE PROCEDURE usp_QuoteRequestTravel_GetDetail (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT * FROM QuoteRequestTravel WHERE quote_request_id = p_quote_request_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequestDomestic_GetDetail $$
CREATE PROCEDURE usp_QuoteRequestDomestic_GetDetail (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT * FROM QuoteRequestDomestic WHERE quote_request_id = p_quote_request_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteRequest_GetList
-- Back-office work queue: unassigned/PENDING requests, or a specific
-- back-office user's assigned queue.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteRequest_GetList $$
CREATE PROCEDURE usp_QuoteRequest_GetList (
    IN  p_status                       VARCHAR(20),
    IN  p_assigned_backoffice_user_id  BIGINT UNSIGNED,
    IN  p_product_id                   BIGINT UNSIGNED,
    IN  p_page_number                  INT,
    IN  p_page_size                    INT,
    OUT o_result_code                  INT,
    OUT o_result_message               VARCHAR(500),
    OUT o_total_count                  BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM QuoteRequests qr
    WHERE (p_status IS NULL OR qr.status = p_status)
      AND (p_assigned_backoffice_user_id IS NULL OR qr.assigned_backoffice_user_id = p_assigned_backoffice_user_id)
      AND (p_product_id IS NULL OR qr.product_id = p_product_id);

    SELECT qr.quote_request_id, qr.ref_no, qr.product_id, p.code AS product_code, qr.client_id,
           qr.requested_by_user_id, qr.channel, qr.status, qr.assigned_backoffice_user_id, qr.created_on
    FROM QuoteRequests qr
    JOIN Products p ON p.product_id = qr.product_id
    WHERE (p_status IS NULL OR qr.status = p_status)
      AND (p_assigned_backoffice_user_id IS NULL OR qr.assigned_backoffice_user_id = p_assigned_backoffice_user_id)
      AND (p_product_id IS NULL OR qr.product_id = p_product_id)
    -- Work-queue order: whatever still needs picking up (PENDING) floats to
    -- the top, then whatever's actively being worked (IN_PROGRESS), then
    -- QUOTED (waiting on the client), with the two terminal states
    -- (EXPIRED/CONVERTED) sinking to the bottom since there's nothing left
    -- to do on them. Oldest-first within each of those groups.
    ORDER BY FIELD(qr.status, 'PENDING', 'IN_PROGRESS', 'QUOTED', 'EXPIRED', 'CONVERTED'), qr.created_on ASC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteRequest_GetSummary
-- Work-queue header counts for the back-office list screen: pending,
-- in-progress and total requests, broken down per manual-quote product
-- (Motor is FIXED_MAPPING/never goes through QuoteRequests, so it's
-- excluded here the same way it's excluded everywhere else in this file).
-- LEFT JOINed from Products (not QuoteRequests) so a product with zero
-- requests today still shows up as a 0/0/0 card instead of disappearing.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteRequest_GetSummary $$
CREATE PROCEDURE usp_QuoteRequest_GetSummary (
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT p.product_id, p.code AS product_code, p.name AS product_name,
           -- COALESCE - SUM over zero joined rows yields NULL, not 0, so an
           -- empty work queue would otherwise hand DBNull to the C# mapper.
           COALESCE(SUM(qr.status = 'PENDING'), 0)     AS pending_count,
           COALESCE(SUM(qr.status = 'IN_PROGRESS'), 0) AS in_progress_count,
           COUNT(qr.quote_request_id)                  AS total_count
    FROM Products p
    LEFT JOIN QuoteRequests qr ON qr.product_id = p.product_id
    WHERE p.pricing_method = 'MANUAL_QUOTE'
    GROUP BY p.product_id, p.code, p.name
    ORDER BY p.code;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequest_AssignBackoffice $$
CREATE PROCEDURE usp_QuoteRequest_AssignBackoffice (
    IN  p_quote_request_id             BIGINT UNSIGNED,
    IN  p_assigned_backoffice_user_id  BIGINT UNSIGNED,
    IN  p_actor_id                     BIGINT UNSIGNED,
    OUT o_result_code                  INT,
    OUT o_result_message               VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_request_id IS NULL OR p_assigned_backoffice_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_request_id and assigned_backoffice_user_id are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE quote_request_id = p_quote_request_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Quote request not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteRequests
    SET assigned_backoffice_user_id = p_assigned_backoffice_user_id,
        status = 'IN_PROGRESS'
    WHERE quote_request_id = p_quote_request_id AND status = 'PENDING';

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'ASSIGN', 'QuoteRequests', p_quote_request_id,
            NULL, JSON_OBJECT('assigned_backoffice_user_id', p_assigned_backoffice_user_id), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteRequest_Expire $$
CREATE PROCEDURE usp_QuoteRequest_Expire (
    IN  p_quote_request_id BIGINT UNSIGNED,
    IN  p_actor_id         BIGINT UNSIGNED,
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_request_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_request_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE quote_request_id = p_quote_request_id AND status <> 'CONVERTED') THEN
        SET o_result_code = 2;
        SET o_result_message = 'Quote request not found or already converted.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteRequests SET status = 'EXPIRED' WHERE quote_request_id = p_quote_request_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'STATUS_CHANGE', 'QuoteRequests', p_quote_request_id,
            NULL, JSON_OBJECT('status', 'EXPIRED'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- QUOTE OFFERS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_QuoteOffer_Create
-- Back office uploads a priced option from one underwriter. Also flips
-- the parent QuoteRequests row to 'QUOTED' the first time an offer is
-- added (stays QUOTED, even with multiple offers, until a purchase
-- converts it).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOffer_Create $$
CREATE PROCEDURE usp_QuoteOffer_Create (
    IN  p_quote_request_id  BIGINT UNSIGNED,
    IN  p_underwriter_id    BIGINT UNSIGNED,
    IN  p_premium_amount    DECIMAL(18,2),
    IN  p_document_path     VARCHAR(255),
    IN  p_uploaded_by_user_id BIGINT UNSIGNED,
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500),
    OUT o_quote_offer_id    BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_request_id IS NULL OR p_underwriter_id IS NULL OR p_premium_amount IS NULL
       OR p_uploaded_by_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_request_id, underwriter_id, premium_amount and uploaded_by_user_id are required.';
        LEAVE proc_label;
    END IF;

    IF p_premium_amount <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'premium_amount must be greater than zero.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteRequests WHERE quote_request_id = p_quote_request_id AND status IN ('IN_PROGRESS','QUOTED')) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Quote request not found or not in a state that accepts offers.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO QuoteOffers (quote_request_id, underwriter_id, premium_amount, document_path,
                              uploaded_by_user_id, uploaded_on, status)
    VALUES (p_quote_request_id, p_underwriter_id, p_premium_amount, p_document_path,
            p_uploaded_by_user_id, NOW(), 'ACTIVE');

    SET o_quote_offer_id = LAST_INSERT_ID();

    UPDATE QuoteRequests SET status = 'QUOTED' WHERE quote_request_id = p_quote_request_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_uploaded_by_user_id, 'CREATE', 'QuoteOffers', o_quote_offer_id,
            NULL, JSON_OBJECT('quote_request_id', p_quote_request_id, 'underwriter_id', p_underwriter_id,
                              'premium_amount', p_premium_amount), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_QuoteOffer_GetListByRequest $$
CREATE PROCEDURE usp_QuoteOffer_GetListByRequest (
    IN  p_quote_request_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_quote_request_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_request_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT qo.quote_offer_id, qo.quote_request_id, qo.underwriter_id, u.name AS underwriter_name,
           qo.premium_amount, qo.document_path, qo.uploaded_by_user_id, qo.uploaded_on, qo.status
    FROM QuoteOffers qo
    JOIN Underwriters u ON u.underwriter_id = qo.underwriter_id
    WHERE qo.quote_request_id = p_quote_request_id AND qo.isdeleted = 0
    ORDER BY qo.premium_amount ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteOffer_Update
-- Back office corrects a mistyped premium/underwriter, or swaps in a
-- replacement document, on an offer that hasn't been acted on yet.
-- Deliberately restricted to status = 'ACTIVE' - once an offer has been
-- SELECTED (a client/agent picked it - possibly already tied to a
-- Purchase) or REJECTED/EXPIRED, editing it out from under that decision
-- would be confusing at best. p_document_path is nullable on the call
-- itself: pass NULL to leave the existing document alone (the "edit
-- premium only, keep the same PDF" case), or a new value to replace it -
-- the API layer decides which by only including the parameter when a new
-- file was actually uploaded.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOffer_Update $$
CREATE PROCEDURE usp_QuoteOffer_Update (
    IN  p_quote_offer_id       BIGINT UNSIGNED,
    IN  p_underwriter_id       BIGINT UNSIGNED,
    IN  p_premium_amount       DECIMAL(18,2),
    IN  p_document_path        VARCHAR(255),
    IN  p_replace_document     TINYINT(1),
    IN  p_actor_id             BIGINT UNSIGNED,
    OUT o_result_code          INT,
    OUT o_result_message       VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_offer_id IS NULL OR p_underwriter_id IS NULL OR p_premium_amount IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id, underwriter_id and premium_amount are required.';
        LEAVE proc_label;
    END IF;

    IF p_premium_amount <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'premium_amount must be greater than zero.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE') THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active quote offer not found (it may have already been selected, rejected, or deleted).';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteOffers
    SET underwriter_id = p_underwriter_id,
        premium_amount = p_premium_amount,
        document_path  = IF(p_replace_document = 1, p_document_path, document_path)
    WHERE quote_offer_id = p_quote_offer_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'QuoteOffers', p_quote_offer_id,
            NULL, JSON_OBJECT('underwriter_id', p_underwriter_id, 'premium_amount', p_premium_amount), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteOffer_Delete (soft delete)
-- Same ACTIVE-only restriction as Update, for the same reason. If this
-- was the LAST remaining active offer on the request, the parent
-- QuoteRequests row drops back from 'QUOTED' to 'IN_PROGRESS' - it
-- shouldn't keep claiming "quoted" once there's nothing left to show
-- the client.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOffer_Delete $$
CREATE PROCEDURE usp_QuoteOffer_Delete (
    IN  p_quote_offer_id BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_quote_request_id BIGINT UNSIGNED;
    DECLARE v_remaining_active INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_offer_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT quote_request_id INTO v_quote_request_id
    FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_quote_request_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active quote offer not found (it may have already been selected, rejected, or deleted).';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteOffers
    SET isdeleted = 1, deleted_by = p_actor_id, deleted_on = NOW()
    WHERE quote_offer_id = p_quote_offer_id;

    SELECT COUNT(*) INTO v_remaining_active
    FROM QuoteOffers
    WHERE quote_request_id = v_quote_request_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_remaining_active = 0 THEN
        UPDATE QuoteRequests SET status = 'IN_PROGRESS' WHERE quote_request_id = v_quote_request_id AND status = 'QUOTED';
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'DELETE', 'QuoteOffers', p_quote_offer_id, NULL, NULL, NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_QuoteOffer_Select
-- Client/agent picks one offer. Marks it SELECTED, marks the other
-- still-ACTIVE offers on the same request REJECTED. Does NOT touch
-- QuoteRequests.status — that becomes CONVERTED only when
-- usp_Purchase_Create actually completes the purchase against this offer.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_QuoteOffer_Select $$
CREATE PROCEDURE usp_QuoteOffer_Select (
    IN  p_quote_offer_id BIGINT UNSIGNED,
    IN  p_actor_type     VARCHAR(20),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_quote_request_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_quote_offer_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'quote_offer_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT quote_request_id INTO v_quote_request_id
    FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE';

    IF v_quote_request_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Active quote offer not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE QuoteOffers SET status = 'SELECTED' WHERE quote_offer_id = p_quote_offer_id;

    UPDATE QuoteOffers
    SET status = 'REJECTED'
    WHERE quote_request_id = v_quote_request_id AND quote_offer_id <> p_quote_offer_id AND isdeleted = 0 AND status = 'ACTIVE';

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), p_actor_id, 'SELECT', 'QuoteOffers', p_quote_offer_id,
            NULL, NULL, NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
