-- =====================================================================
-- Insurance Platform — Stored Procedures: CLIENTS / VEHICLES (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Requires Insurance_API_Schema.sql to have been applied (needs the
-- ClientLoginAttachRequests table and uq_clients_user_id constraint).
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- ---------------------------------------------------------------------
-- usp_Client_ResolveByIdNo
-- Three-way identity check used by the website/WhatsApp self-service
-- purchase flow: NOT_FOUND (brand new), HAS_LOGIN (route to normal
-- login/OTP), NO_LOGIN (the agent-created case — attach-login candidate).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_ResolveByIdNo $$
CREATE PROCEDURE usp_Client_ResolveByIdNo (
    IN  p_id_no VARCHAR(50),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500),
    OUT o_client_id BIGINT UNSIGNED,
    OUT o_match_status VARCHAR(20)   -- NOT_FOUND / HAS_LOGIN / NO_LOGIN
)
proc_label: BEGIN
    DECLARE v_client_id BIGINT UNSIGNED;
    DECLARE v_user_id BIGINT UNSIGNED;

    IF p_id_no IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'id_no is required.';
        LEAVE proc_label;
    END IF;

    SELECT client_id, user_id INTO v_client_id, v_user_id
    FROM Clients
    WHERE id_no = p_id_no AND isdeleted = 0;

    IF v_client_id IS NULL THEN
        SET o_match_status = 'NOT_FOUND';
        SET o_client_id = NULL;
        SET o_result_code = 0;
        SET o_result_message = 'No existing client for this id_no.';
        LEAVE proc_label;
    END IF;

    SET o_client_id = v_client_id;
    SET o_match_status = IF(v_user_id IS NOT NULL, 'HAS_LOGIN', 'NO_LOGIN');

    SELECT client_id, full_name, phone, email, user_id, registered_by_user_id, registration_channel
    FROM Clients
    WHERE client_id = v_client_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_Create
-- Creates a Clients row. p_user_id is optional — set it only when
-- creating a brand-new client together with a brand-new login in the
-- same self-service flow (Users row created first via usp_User_Create,
-- then this proc links it). Leave NULL for agent/support/admin-created
-- clients that get no login by default.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_Create $$
CREATE PROCEDURE usp_Client_Create (
    IN  p_id_no                 VARCHAR(50),
    IN  p_full_name              VARCHAR(150),
    IN  p_dob                    DATE,
    IN  p_email                  VARCHAR(150),
    IN  p_phone                  VARCHAR(20),
    IN  p_address                VARCHAR(255),
    IN  p_kra_pin                VARCHAR(20),
    IN  p_user_id                BIGINT UNSIGNED,
    IN  p_registered_by_user_id  BIGINT UNSIGNED,
    IN  p_registration_channel   VARCHAR(20),
    IN  p_actor_type             VARCHAR(20),
    IN  p_actor_id               BIGINT UNSIGNED,
    OUT o_result_code            INT,
    OUT o_result_message         VARCHAR(500),
    OUT o_client_id              BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_id_no IS NULL OR p_full_name IS NULL OR p_phone IS NULL OR p_registration_channel IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'id_no, full_name, phone and registration_channel are required.';
        LEAVE proc_label;
    END IF;

    IF p_registration_channel NOT IN ('PORTAL','USSD','WHATSAPP','WEBSITE') THEN
        SET o_result_code = 1;
        SET o_result_message = 'registration_channel must be PORTAL, USSD, WHATSAPP or WEBSITE.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Clients WHERE id_no = p_id_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A client with this id_no already exists — call usp_Client_ResolveByIdNo first.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Clients (id_no, full_name, dob, email, phone, address, kra_pin,
                          user_id, registered_by_user_id, registration_channel, created_on)
    VALUES (p_id_no, p_full_name, p_dob, p_email, p_phone, p_address, p_kra_pin,
            p_user_id, p_registered_by_user_id, p_registration_channel, NOW());

    SET o_client_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, o_client_id), 'CREATE', 'Clients', o_client_id,
            NULL,
            JSON_OBJECT('id_no', p_id_no, 'full_name', p_full_name, 'phone', p_phone,
                        'registration_channel', p_registration_channel),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_SelfRegister
-- A brand-new person (never a Client, never a User before) registering
-- themselves from the mobile app or portal. Creates the Users row AND the
-- Clients row in ONE transaction — unlike the usp_User_Create ->
-- usp_Client_Create two-call sequence used elsewhere, this can't be split
-- into two separate proc calls from the API layer, because a failure
-- partway through (e.g. a duplicate slipping in between the two calls)
-- would leave an orphaned Users row with no linked Client. One proc, one
-- transaction, both rows or neither.
--
-- The new Users row is created INACTIVE with must_change_password = 0
-- (they just chose their own password — no reason to force a change) and
-- stays that way until the API layer calls usp_Otp_Verify (purpose =
-- 'REGISTER') and then usp_User_UpdateStatus to flip it to ACTIVE. This
-- proc does not send the OTP itself — same separation of concerns as the
-- rest of Auth: this proc only creates the account, whether it's an admin,
-- an agent, or SCAPI notification calls happen in C#.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_SelfRegister $$
CREATE PROCEDURE usp_Client_SelfRegister (
    IN  p_id_no               VARCHAR(50),
    IN  p_full_name            VARCHAR(150),
    IN  p_dob                  DATE,
    IN  p_email                VARCHAR(150),
    IN  p_phone                VARCHAR(20),
    IN  p_address              VARCHAR(255),
    IN  p_kra_pin               VARCHAR(20),
    IN  p_password_hash        VARCHAR(255),
    IN  p_registration_channel VARCHAR(20),
    OUT o_result_code          INT,
    OUT o_result_message       VARCHAR(500),
    OUT o_user_id              BIGINT UNSIGNED,
    OUT o_client_id            BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_client_role_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_id_no IS NULL OR p_full_name IS NULL OR p_phone IS NULL
       OR p_password_hash IS NULL OR p_registration_channel IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'id_no, full_name, phone, password_hash and registration_channel are required.';
        LEAVE proc_label;
    END IF;

    -- Self-registration is only reachable from the client portal or the
    -- mobile app - USSD, WhatsApp and the public website never carry an
    -- individual login (they authenticate as a ChannelServiceAccount
    -- instead, per the channel-auth design). This is deliberately narrower
    -- than Clients.registration_channel's table-level CHECK constraint,
    -- which still allows all five values for OTHER creation paths (e.g.
    -- usp_Client_Create, used when an agent registers a client on someone's
    -- behalf regardless of which channel that client originally came in on).
    IF p_registration_channel NOT IN ('PORTAL','MOBILE') THEN
        SET o_result_code = 1;
        SET o_result_message = 'registration_channel must be PORTAL or MOBILE for self-registration.';
        LEAVE proc_label;
    END IF;

    -- Two separate existence checks, deliberately not one combined check:
    -- a Users row with this id_no means "you already have a login — log in
    -- instead." A Clients row with this id_no but no Users row means "you
    -- (or an agent on your behalf) already exist as a client — use the
    -- attach-login flow (usp_Client_AttachLogin), not self-registration."
    -- Both are "duplicate," but the API layer can tell them apart from
    -- o_result_message if it ever needs to.
    IF EXISTS (SELECT 1 FROM Users WHERE id_no = p_id_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'An account already exists for this ID number — please log in instead.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Clients WHERE id_no = p_id_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A client record already exists for this ID number — use the attach-login flow instead of registering again.';
        LEAVE proc_label;
    END IF;

    SELECT role_id INTO v_client_role_id FROM Roles WHERE role_code = 'CL' AND is_active = 1;

    IF v_client_role_id IS NULL THEN
        SET o_result_code = 99;
        SET o_result_message = 'Client role is not configured.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash,
                        status, must_change_password, created_by, created_on)
    VALUES (v_client_role_id, p_id_no, p_full_name, p_email, p_phone, p_password_hash,
            'INACTIVE', 0, NULL, NOW());

    SET o_user_id = LAST_INSERT_ID();

    INSERT INTO Clients (id_no, full_name, dob, email, phone, address, kra_pin,
                          user_id, registered_by_user_id, registration_channel, created_on)
    VALUES (p_id_no, p_full_name, p_dob, p_email, p_phone, p_address, p_kra_pin,
            o_user_id, NULL, p_registration_channel, NOW());

    SET o_client_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', o_user_id, 'CREATE', 'Users', o_user_id,
            NULL,
            JSON_OBJECT('role_id', v_client_role_id, 'id_no', p_id_no, 'full_name', p_full_name,
                        'phone', p_phone, 'email', p_email, 'self_registered', TRUE),
            NOW());

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', o_user_id, 'CREATE', 'Clients', o_client_id,
            NULL,
            JSON_OBJECT('id_no', p_id_no, 'full_name', p_full_name, 'phone', p_phone,
                        'registration_channel', p_registration_channel),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_GetById
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_GetById $$
CREATE PROCEDURE usp_Client_GetById (
    IN  p_client_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    SELECT client_id, id_no, full_name, dob, email, phone, address, kra_pin,
           user_id, registered_by_user_id, registration_channel, created_on
    FROM Clients
    WHERE client_id = p_client_id AND isdeleted = 0;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_GetList
-- Paginated + searchable. p_registered_by_user_id lets an Agent list
-- only "their" clients; Support_Agent/Agent_admin pass NULL to see all
-- (that authorization decision is made at the API layer, per RBAC).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_GetList $$
CREATE PROCEDURE usp_Client_GetList (
    IN  p_registered_by_user_id BIGINT UNSIGNED,
    IN  p_search                VARCHAR(150),   -- matches against id_no, full_name, phone
    IN  p_page_number           INT,
    IN  p_page_size             INT,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500),
    OUT o_total_count           BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;
    DECLARE v_search VARCHAR(152);

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;
    SET v_search = CONCAT('%', p_search, '%');

    SELECT COUNT(*) INTO o_total_count
    FROM Clients c
    WHERE c.isdeleted = 0
      AND (p_registered_by_user_id IS NULL OR c.registered_by_user_id = p_registered_by_user_id)
      AND (p_search IS NULL OR c.id_no LIKE v_search OR c.full_name LIKE v_search OR c.phone LIKE v_search);

    SELECT c.client_id, c.id_no, c.full_name, c.phone, c.email, c.user_id,
           c.registered_by_user_id, c.registration_channel, c.created_on
    FROM Clients c
    WHERE c.isdeleted = 0
      AND (p_registered_by_user_id IS NULL OR c.registered_by_user_id = p_registered_by_user_id)
      AND (p_search IS NULL OR c.id_no LIKE v_search OR c.full_name LIKE v_search OR c.phone LIKE v_search)
    ORDER BY c.created_on DESC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_GetSummary
-- Single-row rollup for dashboard stat cards: total (non-deleted) clients,
-- plus how many were registered this calendar month - a simple "growth"
-- number since Clients has no status column of its own to break down
-- (only isdeleted, already excluded). Same p_registered_by_user_id scoping
-- convention as usp_Client_GetList: NULL for platform-wide (SuperAdmin/
-- AgentAdmin/SupportAgent), an agent's own user_id for their own dashboard.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_GetSummary $$
CREATE PROCEDURE usp_Client_GetSummary (
    IN  p_registered_by_user_id BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500)
)
BEGIN
    SELECT
        COUNT(*) AS total_count,
        COALESCE(SUM(
            YEAR(c.created_on) = YEAR(CURDATE()) AND MONTH(c.created_on) = MONTH(CURDATE())
        ), 0) AS new_this_month_count
    FROM Clients c
    WHERE c.isdeleted = 0
      AND (p_registered_by_user_id IS NULL OR c.registered_by_user_id = p_registered_by_user_id);

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_Update
-- Agent/Support/Agent_admin editing a client's details, or the client
-- editing their own via the portal (API layer enforces who may call this
-- for which client_id).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_Update $$
CREATE PROCEDURE usp_Client_Update (
    IN  p_client_id      BIGINT UNSIGNED,
    IN  p_full_name      VARCHAR(150),
    IN  p_dob            DATE,
    IN  p_email          VARCHAR(150),
    IN  p_phone          VARCHAR(20),
    IN  p_address        VARCHAR(255),
    IN  p_kra_pin        VARCHAR(20),
    IN  p_actor_type     VARCHAR(20),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
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

    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT JSON_OBJECT('full_name', full_name, 'dob', dob, 'email', email,
                        'phone', phone, 'address', address, 'kra_pin', kra_pin)
    INTO v_old
    FROM Clients WHERE client_id = p_client_id AND isdeleted = 0;

    IF v_old IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Clients
    SET full_name = COALESCE(p_full_name, full_name),
        dob        = COALESCE(p_dob, dob),
        email      = COALESCE(p_email, email),
        phone      = COALESCE(p_phone, phone),
        address    = COALESCE(p_address, address),
        kra_pin    = COALESCE(p_kra_pin, kra_pin)
    WHERE client_id = p_client_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, p_client_id), 'UPDATE', 'Clients', p_client_id,
            v_old,
            JSON_OBJECT('full_name', p_full_name, 'dob', p_dob, 'email', p_email,
                        'phone', p_phone, 'address', p_address, 'kra_pin', p_kra_pin),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_AttachLogin
-- Called AFTER the API layer has already verified the OTP (usp_Otp_Verify,
-- purpose='ATTACH_LOGIN', sent to the client's ON-FILE contact — never a
-- freshly-typed one). Creates the client's first Users row and links it.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_AttachLogin $$
CREATE PROCEDURE usp_Client_AttachLogin (
    IN  p_client_id       BIGINT UNSIGNED,
    IN  p_password_hash   VARCHAR(255),
    OUT o_result_code     INT,
    OUT o_result_message  VARCHAR(500),
    OUT o_user_id         BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_client_role_id BIGINT UNSIGNED;
    DECLARE v_id_no VARCHAR(50);
    DECLARE v_full_name VARCHAR(150);
    DECLARE v_email VARCHAR(150);
    DECLARE v_phone VARCHAR(20);
    DECLARE v_existing_user_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_client_id IS NULL OR p_password_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id and password_hash are required.';
        LEAVE proc_label;
    END IF;

    SELECT id_no, full_name, email, phone, user_id
    INTO v_id_no, v_full_name, v_email, v_phone, v_existing_user_id
    FROM Clients WHERE client_id = p_client_id AND isdeleted = 0;

    IF v_id_no IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    IF v_existing_user_id IS NOT NULL THEN
        SET o_result_code = 4;
        SET o_result_message = 'This client already has a login.';
        LEAVE proc_label;
    END IF;

    SELECT role_id INTO v_client_role_id FROM Roles WHERE role_code = 'CL' AND is_active = 1;

    IF v_client_role_id IS NULL THEN
        SET o_result_code = 4;
        SET o_result_message = 'CLIENT role is not configured.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash,
                        status, must_change_password, created_by, created_on)
    VALUES (v_client_role_id, v_id_no, v_full_name, v_email, v_phone, p_password_hash,
            'ACTIVE', 0, NULL, NOW());

    SET o_user_id = LAST_INSERT_ID();

    UPDATE Clients SET user_id = o_user_id WHERE client_id = p_client_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('CLIENT', p_client_id, 'LOGIN_ATTACHED', 'Clients', p_client_id,
            NULL, JSON_OBJECT('user_id', o_user_id), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_FlagLoginAttachIssue
-- Called when the ATTACH_LOGIN OTP could not be verified against the
-- on-file contact (expired/too many attempts) — records the attempt so
-- Support can manually verify the person and correct the on-file contact.
-- The purchase that triggered this flow proceeds regardless, under the
-- same client_id — this only affects whether login is granted.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_FlagLoginAttachIssue $$
CREATE PROCEDURE usp_Client_FlagLoginAttachIssue (
    IN  p_client_id        BIGINT UNSIGNED,
    IN  p_attempted_phone  VARCHAR(20),
    IN  p_attempted_email  VARCHAR(150),
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500),
    OUT o_request_id       BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO ClientLoginAttachRequests (client_id, attempted_phone, attempted_email, status, flagged_on)
    VALUES (p_client_id, p_attempted_phone, p_attempted_email, 'PENDING', NOW());

    SET o_request_id = LAST_INSERT_ID();

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_ResolveLoginAttachRequest
-- Support reviews a flagged attach attempt. If VERIFIED, optionally
-- corrects the on-file phone/email (the client can then retry the
-- normal ATTACH_LOGIN OTP flow with corrected contact info).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_ResolveLoginAttachRequest $$
CREATE PROCEDURE usp_Client_ResolveLoginAttachRequest (
    IN  p_request_id     BIGINT UNSIGNED,
    IN  p_action         VARCHAR(20),   -- VERIFIED / REJECTED
    IN  p_corrected_phone VARCHAR(20),
    IN  p_corrected_email VARCHAR(150),
    IN  p_actor_id       BIGINT UNSIGNED,   -- Support_Agent user_id
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_client_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_request_id IS NULL OR p_action IS NULL OR p_actor_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'request_id, action and actor_id are required.';
        LEAVE proc_label;
    END IF;

    IF p_action NOT IN ('VERIFIED','REJECTED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'action must be VERIFIED or REJECTED.';
        LEAVE proc_label;
    END IF;

    SELECT client_id INTO v_client_id
    FROM ClientLoginAttachRequests
    WHERE request_id = p_request_id AND status = 'PENDING';

    IF v_client_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Pending request not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE ClientLoginAttachRequests
    SET status = p_action, resolved_by_user_id = p_actor_id, resolved_on = NOW()
    WHERE request_id = p_request_id;

    IF p_action = 'VERIFIED' AND (p_corrected_phone IS NOT NULL OR p_corrected_email IS NOT NULL) THEN
        UPDATE Clients
        SET phone = COALESCE(p_corrected_phone, phone),
            email = COALESCE(p_corrected_email, email)
        WHERE client_id = v_client_id;
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, CONCAT('LOGIN_ATTACH_', p_action), 'ClientLoginAttachRequests', p_request_id,
            NULL, JSON_OBJECT('corrected_phone', p_corrected_phone, 'corrected_email', p_corrected_email), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_FlagDuplicate
-- Support manually flags two DISTINCT client_id values (different id_no)
-- as suspected duplicates of the same real person.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_FlagDuplicate $$
CREATE PROCEDURE usp_Client_FlagDuplicate (
    IN  p_client_id_a       BIGINT UNSIGNED,
    IN  p_client_id_b       BIGINT UNSIGNED,
    IN  p_flagged_by_user_id BIGINT UNSIGNED,
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500),
    OUT o_duplicate_id      BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_client_id_a IS NULL OR p_client_id_b IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id_a and client_id_b are required.';
        LEAVE proc_label;
    END IF;

    IF p_client_id_a = p_client_id_b THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id_a and client_id_b must be different clients.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id_a AND isdeleted = 0)
       OR NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id_b AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'One or both clients not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO PotentialDuplicateClients (client_id_a, client_id_b, flagged_by_user_id, status, flagged_on)
    VALUES (p_client_id_a, p_client_id_b, p_flagged_by_user_id, 'PENDING', NOW());

    SET o_duplicate_id = LAST_INSERT_ID();

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_MergeDuplicate
-- Merges client_id_b INTO client_id_a: reassigns Vehicles, Purchases and
-- QuoteRequests to client_id_a, transfers B's login to A if A has none
-- (blocks the merge if BOTH already have active logins — that needs
-- manual resolution), then soft-deletes B.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_MergeDuplicate $$
CREATE PROCEDURE usp_Client_MergeDuplicate (
    IN  p_duplicate_id   BIGINT UNSIGNED,
    IN  p_actor_id       BIGINT UNSIGNED,   -- Support_Agent/Agent_admin performing the merge
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_client_id_a BIGINT UNSIGNED;
    DECLARE v_client_id_b BIGINT UNSIGNED;
    DECLARE v_user_id_a BIGINT UNSIGNED;
    DECLARE v_user_id_b BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_duplicate_id IS NULL OR p_actor_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'duplicate_id and actor_id are required.';
        LEAVE proc_label;
    END IF;

    SELECT client_id_a, client_id_b INTO v_client_id_a, v_client_id_b
    FROM PotentialDuplicateClients
    WHERE duplicate_id = p_duplicate_id AND status = 'PENDING';

    IF v_client_id_a IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Pending duplicate flag not found.';
        LEAVE proc_label;
    END IF;

    SELECT user_id INTO v_user_id_a FROM Clients WHERE client_id = v_client_id_a AND isdeleted = 0;
    SELECT user_id INTO v_user_id_b FROM Clients WHERE client_id = v_client_id_b AND isdeleted = 0;

    IF v_user_id_a IS NOT NULL AND v_user_id_b IS NOT NULL THEN
        SET o_result_code = 4;
        SET o_result_message = 'Both records have active logins — cannot auto-merge, resolve manually.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- Reassign owned records to the surviving client (A)
    UPDATE Vehicles SET client_id = v_client_id_a WHERE client_id = v_client_id_b;
    UPDATE Purchases SET client_id = v_client_id_a WHERE client_id = v_client_id_b;
    UPDATE QuoteRequests SET client_id = v_client_id_a WHERE client_id = v_client_id_b;

    -- Transfer B's login to A if A has none (clear B first to avoid the
    -- uq_clients_user_id unique constraint colliding mid-update)
    IF v_user_id_a IS NULL AND v_user_id_b IS NOT NULL THEN
        UPDATE Clients SET user_id = NULL WHERE client_id = v_client_id_b;
        UPDATE Clients SET user_id = v_user_id_b WHERE client_id = v_client_id_a;
    END IF;

    UPDATE Clients SET isdeleted = 1 WHERE client_id = v_client_id_b;

    UPDATE PotentialDuplicateClients
    SET status = 'MERGED', resolved_by_user_id = p_actor_id, resolved_on = NOW()
    WHERE duplicate_id = p_duplicate_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'MERGE', 'Clients', v_client_id_a,
            JSON_OBJECT('merged_from_client_id', v_client_id_b), JSON_OBJECT('surviving_client_id', v_client_id_a), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_RejectDuplicate
-- Support determines the two flagged clients are NOT the same person.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_RejectDuplicate $$
CREATE PROCEDURE usp_Client_RejectDuplicate (
    IN  p_duplicate_id   BIGINT UNSIGNED,
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

    IF p_duplicate_id IS NULL OR p_actor_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'duplicate_id and actor_id are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM PotentialDuplicateClients WHERE duplicate_id = p_duplicate_id AND status = 'PENDING') THEN
        SET o_result_code = 2;
        SET o_result_message = 'Pending duplicate flag not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE PotentialDuplicateClients
    SET status = 'REJECTED', resolved_by_user_id = p_actor_id, resolved_on = NOW()
    WHERE duplicate_id = p_duplicate_id;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Client_Delete (soft delete)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Client_Delete $$
CREATE PROCEDURE usp_Client_Delete (
    IN  p_client_id      BIGINT UNSIGNED,
    IN  p_actor_type     VARCHAR(20),
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

    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Clients SET isdeleted = 1 WHERE client_id = p_client_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), p_actor_id, 'DELETE', 'Clients', p_client_id, NULL, NULL, NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- =====================================================================
-- VEHICLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_Vehicle_GetByRegNo
-- Dedup lookup — call before Create so a renewal/re-registration reuses
-- the existing vehicle_id instead of creating a duplicate.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_GetByRegNo $$
CREATE PROCEDURE usp_Vehicle_GetByRegNo (
    IN  p_reg_no VARCHAR(100),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_reg_no IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'reg_no is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE reg_no = p_reg_no AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle not found.';
        LEAVE proc_label;
    END IF;

    SELECT vehicle_id, client_id, make, model, reg_no, chassis_no, engine_no,
           yearofmanufacture, vehicle_type, p_bodytype, fueltype, cubiccapacity,
           color, logbook, created_by, created_on
    FROM Vehicles
    WHERE reg_no = p_reg_no AND isdeleted = 0;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Vehicle_Create
-- Dedupes on reg_no/chassis_no (whichever is provided) before inserting.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_Create $$
CREATE PROCEDURE usp_Vehicle_Create (
    IN  p_client_id           BIGINT UNSIGNED,
    IN  p_make                VARCHAR(100),
    IN  p_model                VARCHAR(100),
    IN  p_reg_no                VARCHAR(100),
    IN  p_chassis_no             VARCHAR(100),
    IN  p_engine_no               VARCHAR(100),
    IN  p_yearofmanufacture        YEAR,
    IN  p_vehicle_type               VARCHAR(200),
    IN  p_body_type                     VARCHAR(100),   -- maps to Vehicles.p_bodytype column; renamed to avoid parameter/column name collision
    IN  p_fueltype                       VARCHAR(50),
    IN  p_cubiccapacity                    VARCHAR(100),
    IN  p_color                              VARCHAR(100),
    IN  p_logbook                              VARCHAR(100),
    IN  p_actor_type                             VARCHAR(20),
    IN  p_actor_id                                 BIGINT UNSIGNED,
    OUT o_result_code                                INT,
    OUT o_result_message                               VARCHAR(500),
    OUT o_vehicle_id                                     BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    IF p_reg_no IS NOT NULL AND EXISTS (SELECT 1 FROM Vehicles WHERE reg_no = p_reg_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A vehicle with this registration number already exists — use usp_Vehicle_GetByRegNo.';
        LEAVE proc_label;
    END IF;

    IF p_chassis_no IS NOT NULL AND EXISTS (SELECT 1 FROM Vehicles WHERE chassis_no = p_chassis_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A vehicle with this chassis number already exists.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Vehicles (client_id, make, model, reg_no, chassis_no, engine_no,
                           yearofmanufacture, vehicle_type, p_bodytype, fueltype,
                           cubiccapacity, color, logbook, created_by, created_on)
    VALUES (p_client_id, p_make, p_model, p_reg_no, p_chassis_no, p_engine_no,
            p_yearofmanufacture, p_vehicle_type, p_body_type, p_fueltype,
            p_cubiccapacity, p_color, p_logbook,
            IF(p_actor_type = 'USER', p_actor_id, NULL), NOW());

    SET o_vehicle_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, p_client_id), 'CREATE', 'Vehicles', o_vehicle_id,
            NULL, JSON_OBJECT('client_id', p_client_id, 'reg_no', p_reg_no, 'chassis_no', p_chassis_no), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Vehicle_GetById
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_GetById $$
CREATE PROCEDURE usp_Vehicle_GetById (
    IN  p_vehicle_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_vehicle_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE vehicle_id = p_vehicle_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle not found.';
        LEAVE proc_label;
    END IF;

    SELECT vehicle_id, client_id, make, model, reg_no, chassis_no, engine_no,
           yearofmanufacture, vehicle_type, p_bodytype, fueltype, cubiccapacity,
           color, logbook, created_by, created_on
    FROM Vehicles
    WHERE vehicle_id = p_vehicle_id AND isdeleted = 0;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Vehicle_GetListByClient
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_GetListByClient $$
CREATE PROCEDURE usp_Vehicle_GetListByClient (
    IN  p_client_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_client_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'client_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT vehicle_id, client_id, make, model, reg_no, chassis_no, engine_no,
           yearofmanufacture, vehicle_type, p_bodytype, fueltype, cubiccapacity,
           color, logbook, created_on
    FROM Vehicles
    WHERE client_id = p_client_id AND isdeleted = 0
    ORDER BY created_on DESC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Vehicle_Update
-- Re-checks reg_no/chassis_no uniqueness if either is being changed.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_Update $$
CREATE PROCEDURE usp_Vehicle_Update (
    IN  p_vehicle_id      BIGINT UNSIGNED,
    IN  p_make            VARCHAR(100),
    IN  p_model           VARCHAR(100),
    IN  p_reg_no          VARCHAR(100),
    IN  p_chassis_no      VARCHAR(100),
    IN  p_engine_no       VARCHAR(100),
    IN  p_yearofmanufacture YEAR,
    IN  p_vehicle_type    VARCHAR(200),
    IN  p_body_type       VARCHAR(100),   -- maps to Vehicles.p_bodytype column; renamed to avoid parameter/column name collision
    IN  p_fueltype        VARCHAR(50),
    IN  p_cubiccapacity   VARCHAR(100),
    IN  p_color           VARCHAR(100),
    IN  p_logbook         VARCHAR(100),
    IN  p_actor_type      VARCHAR(20),
    IN  p_actor_id        BIGINT UNSIGNED,
    OUT o_result_code     INT,
    OUT o_result_message  VARCHAR(500)
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

    IF p_vehicle_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT JSON_OBJECT('make', make, 'model', model, 'reg_no', reg_no, 'chassis_no', chassis_no,
                        'color', color, 'cubiccapacity', cubiccapacity)
    INTO v_old
    FROM Vehicles WHERE vehicle_id = p_vehicle_id AND isdeleted = 0;

    IF v_old IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle not found.';
        LEAVE proc_label;
    END IF;

    IF p_reg_no IS NOT NULL AND EXISTS (
        SELECT 1 FROM Vehicles WHERE reg_no = p_reg_no AND isdeleted = 0 AND vehicle_id <> p_vehicle_id
    ) THEN
        SET o_result_code = 3;
        SET o_result_message = 'Another vehicle already uses this registration number.';
        LEAVE proc_label;
    END IF;

    IF p_chassis_no IS NOT NULL AND EXISTS (
        SELECT 1 FROM Vehicles WHERE chassis_no = p_chassis_no AND isdeleted = 0 AND vehicle_id <> p_vehicle_id
    ) THEN
        SET o_result_code = 3;
        SET o_result_message = 'Another vehicle already uses this chassis number.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Vehicles
    SET make              = COALESCE(p_make, make),
        model              = COALESCE(p_model, model),
        reg_no             = COALESCE(p_reg_no, reg_no),
        chassis_no         = COALESCE(p_chassis_no, chassis_no),
        engine_no          = COALESCE(p_engine_no, engine_no),
        yearofmanufacture  = COALESCE(p_yearofmanufacture, yearofmanufacture),
        vehicle_type       = COALESCE(p_vehicle_type, vehicle_type),
        p_bodytype         = COALESCE(p_body_type, p_bodytype),
        fueltype           = COALESCE(p_fueltype, fueltype),
        cubiccapacity      = COALESCE(p_cubiccapacity, cubiccapacity),
        color              = COALESCE(p_color, color),
        logbook            = COALESCE(p_logbook, logbook)
    WHERE vehicle_id = p_vehicle_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), p_actor_id, 'UPDATE', 'Vehicles', p_vehicle_id,
            v_old, JSON_OBJECT('reg_no', p_reg_no, 'chassis_no', p_chassis_no, 'color', p_color), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Vehicle_Delete (soft delete)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Vehicle_Delete $$
CREATE PROCEDURE usp_Vehicle_Delete (
    IN  p_vehicle_id     BIGINT UNSIGNED,
    IN  p_actor_type     VARCHAR(20),
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

    IF p_vehicle_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'vehicle_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE vehicle_id = p_vehicle_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Vehicles
    SET isdeleted = 1, deleted_by = IF(p_actor_type = 'USER', p_actor_id, NULL), deleted_on = NOW()
    WHERE vehicle_id = p_vehicle_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), p_actor_id, 'DELETE', 'Vehicles', p_vehicle_id, NULL, NULL, NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
