-- =====================================================================
-- Insurance Platform — Stored Procedures: AUTH / RBAC (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Covers: Roles/Permissions lookup, User CRUD + login support, OTP,
--         ChannelServiceAccount lookup for USSD/WhatsApp/Website-guest.
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- ---------------------------------------------------------------------
-- usp_Role_GetPermissions
-- Returns the permission codes granted to a role — used by the API layer
-- to build policy claims (e.g. embed into JWT, or check ad-hoc).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Role_GetPermissions $$
CREATE PROCEDURE usp_Role_GetPermissions (
    IN  p_role_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_role_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'role_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Role not found.';
        LEAVE proc_label;
    END IF;

    SELECT p.permission_id, p.code, p.description
    FROM RolePermissions rp
    JOIN Permissions p ON p.permission_id = rp.permission_id
    WHERE rp.role_id = p_role_id
    ORDER BY p.code;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_Create
-- Creates a staff/portal-login user (Super_Admin -> Agent_admin,
-- Agent_admin -> Agent/Support_Agent, or a Client activating login).
-- Caller (API layer) has already authorized this action - which role_code
-- a given caller is allowed to create - proc does not re-check role
-- permissions, only data integrity. role_code -> role_id resolution
-- happens here, same pattern as usp_Client_SelfRegister's 'CL' lookup.
-- Account starts ACTIVE with must_change_password=1 - no OTP round-trip
-- like client self-registration, since a staff member creating another
-- staff member's account is already an authenticated, authorized action.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_Create $$
CREATE PROCEDURE usp_User_Create (
    IN  p_role_code      VARCHAR(10),   -- AA / AG / SP
    IN  p_id_no          VARCHAR(50),
    IN  p_full_name      VARCHAR(150),
    IN  p_email          VARCHAR(150),
    IN  p_phone          VARCHAR(20),
    IN  p_password_hash  VARCHAR(255),
    IN  p_actor_type     VARCHAR(20),   -- USER / CHANNEL_SERVICE / NULL (self-registration)
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_user_id        BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_role_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    -- Validation
    IF p_role_code IS NULL OR p_id_no IS NULL OR p_full_name IS NULL
       OR p_phone IS NULL OR p_password_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'role_code, id_no, full_name, phone and password_hash are required.';
        LEAVE proc_label;
    END IF;

    SELECT role_id INTO v_role_id FROM Roles WHERE role_code = p_role_code AND is_active = 1;

    IF v_role_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'Invalid or inactive role_code.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Users WHERE id_no = p_id_no AND isdeleted = 0) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A user with this id_no already exists.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash,
                        status, must_change_password, created_by, created_on)
    VALUES (v_role_id, p_id_no, p_full_name, p_email, p_phone, p_password_hash,
            'ACTIVE', 1, IF(p_actor_type = 'USER', p_actor_id, NULL), NOW());

    SET o_user_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), COALESCE(p_actor_id, o_user_id), 'CREATE', 'Users', o_user_id,
            NULL,
            JSON_OBJECT('role_code', p_role_code, 'id_no', p_id_no, 'full_name', p_full_name,
                        'phone', p_phone, 'email', p_email),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_GetByIdNoForLogin
-- Step 1 of login: fetch the user + password_hash by id_no so the API
-- layer can verify the password (bcrypt/argon2 verification happens in
-- C#, not in SQL) before issuing an OTP.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_GetByIdNoForLogin $$
CREATE PROCEDURE usp_User_GetByIdNoForLogin (
    IN  p_id_no VARCHAR(50),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_unlock_user_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_id_no IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'id_no is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE id_no = p_id_no AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    -- Auto-unlock: if this account is LOCKED and its cooldown
    -- (locked_until) has passed, silently reactivate it and clear the
    -- failed-attempt counter before returning the row - the caller
    -- (AuthService.LoginAsync) then sees a normal ACTIVE user and proceeds
    -- with the password check as usual. If still within the cooldown, this
    -- does nothing and the SELECT below returns status = 'LOCKED' as-is,
    -- which AuthService checks for and rejects with a clear message.
    SELECT user_id INTO v_unlock_user_id
    FROM Users
    WHERE id_no = p_id_no AND isdeleted = 0
      AND status = 'LOCKED' AND locked_until IS NOT NULL AND locked_until <= NOW();

    IF v_unlock_user_id IS NOT NULL THEN
        START TRANSACTION;

        UPDATE Users
        SET status = 'ACTIVE', failed_login_attempts = 0, locked_until = NULL
        WHERE user_id = v_unlock_user_id;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES ('USER', v_unlock_user_id, 'STATUS_CHANGE', 'Users', v_unlock_user_id,
                JSON_OBJECT('status', 'LOCKED'),
                JSON_OBJECT('status', 'ACTIVE', 'reason', 'lockout_cooldown_expired'),
                NOW());

        COMMIT;
    END IF;

    SELECT u.user_id, u.role_id, r.role_code, r.name AS role_name, u.full_name,
           u.email, u.phone, u.password_hash, u.status, u.must_change_password
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.id_no = p_id_no AND u.isdeleted = 0;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_RecordFailedLogin
-- Called after a wrong-password attempt. 5 consecutive failures locks the
-- account for a 15-minute cooldown - see usp_User_GetByIdNoForLogin for
-- the matching auto-unlock check.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_RecordFailedLogin $$
CREATE PROCEDURE usp_User_RecordFailedLogin (
    IN  p_user_id        BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_attempts TINYINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Users
    SET failed_login_attempts = failed_login_attempts + 1
    WHERE user_id = p_user_id;

    SELECT failed_login_attempts INTO v_attempts FROM Users WHERE user_id = p_user_id;

    IF v_attempts >= 5 THEN
        UPDATE Users
        SET status = 'LOCKED', locked_until = DATE_ADD(NOW(), INTERVAL 15 MINUTE)
        WHERE user_id = p_user_id;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES ('USER', p_user_id, 'STATUS_CHANGE', 'Users', p_user_id,
                JSON_OBJECT('status', 'ACTIVE'),
                JSON_OBJECT('status', 'LOCKED', 'reason', 'too_many_failed_logins', 'attempts', v_attempts),
                NOW());
    END IF;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_RecordSuccessfulLogin
-- Called right after a correct password check. Clears the failed-attempt
-- counter/lock state and stamps last_login_on.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_RecordSuccessfulLogin $$
CREATE PROCEDURE usp_User_RecordSuccessfulLogin (
    IN  p_user_id        BIGINT UNSIGNED,
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

    IF p_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Users
    SET failed_login_attempts = 0, locked_until = NULL, last_login_on = NOW()
    WHERE user_id = p_user_id;

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_GetById
-- General profile fetch (no password_hash returned).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_GetById $$
CREATE PROCEDURE usp_User_GetById (
    IN  p_user_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    SELECT u.user_id, u.role_id, r.role_code, r.name AS role_name, u.id_no, u.full_name,
           u.email, u.phone, u.status, u.must_change_password, u.created_by,
           u.created_on, u.last_login_on
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id AND u.isdeleted = 0;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_GetList
-- Paginated listing, e.g. Agent_admin viewing agents/support they manage,
-- Super_Admin viewing all Agent_admins, or the Quote Requests screen's
-- "assign to a specific Support person" picker. Filters are optional
-- (NULL = ignore). Filters by role_code (e.g. 'SP'), not the opaque
-- role_id, since every caller of this proc knows the role by its code,
-- not its auto-increment id - this wasn't called from anywhere yet when
-- it was first written, so changing the filter shape here doesn't break
-- anything.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_GetList $$
CREATE PROCEDURE usp_User_GetList (
    IN  p_role_code          VARCHAR(20),
    IN  p_created_by_user_id BIGINT UNSIGNED,
    IN  p_status             VARCHAR(20),
    IN  p_page_number        INT,
    IN  p_page_size          INT,
    OUT o_result_code        INT,
    OUT o_result_message     VARCHAR(500),
    OUT o_total_count        BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.isdeleted = 0
      AND (p_role_code IS NULL OR r.role_code = p_role_code)
      AND (p_created_by_user_id IS NULL OR u.created_by = p_created_by_user_id)
      AND (p_status IS NULL OR u.status = p_status);

    SELECT u.user_id, u.role_id, r.role_code, r.name AS role_name, u.id_no, u.full_name,
           u.email, u.phone, u.status, u.created_by, u.created_on, u.last_login_on
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.isdeleted = 0
      AND (p_role_code IS NULL OR r.role_code = p_role_code)
      AND (p_created_by_user_id IS NULL OR u.created_by = p_created_by_user_id)
      AND (p_status IS NULL OR u.status = p_status)
    ORDER BY u.full_name ASC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_GetAgentCounts
-- Single-row rollup for the dashboard's "Total Agents"/"Active Agents"
-- widgets. total_agent_count is every non-deleted user with role_code
-- 'AG', regardless of activity. active_agent_count narrows that to agents
-- who personally executed at least one purchase in the last 30 days -
-- "active" is defined by recent selling activity here, not the Users.status
-- column (ACTIVE/INACTIVE/LOCKED is a login-eligibility flag, a different
-- concept - a status-ACTIVE agent who hasn't sold anything in a month
-- still counts toward total_agent_count but not active_agent_count).
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- usp_User_UpdatePassword
-- Used for both "set new password after must_change_password" and
-- forgot-password reset flows. Password hash is computed in C#.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_UpdatePassword $$
CREATE PROCEDURE usp_User_UpdatePassword (
    IN  p_user_id           BIGINT UNSIGNED,
    IN  p_new_password_hash VARCHAR(255),
    IN  p_actor_type        VARCHAR(20),
    IN  p_actor_id          BIGINT UNSIGNED,
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

    IF p_user_id IS NULL OR p_new_password_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id and new_password_hash are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Users
    SET password_hash = p_new_password_hash,
        must_change_password = 0
    WHERE user_id = p_user_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), COALESCE(p_actor_id, p_user_id), 'PASSWORD_CHANGE', 'Users', p_user_id,
            NULL, JSON_OBJECT('event', 'password_changed'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_UpdateStatus
-- Activate / deactivate / lock a user account.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_UpdateStatus $$
CREATE PROCEDURE usp_User_UpdateStatus (
    IN  p_user_id        BIGINT UNSIGNED,
    IN  p_status         VARCHAR(20),
    IN  p_actor_type     VARCHAR(20),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_user_id IS NULL OR p_status IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id and status are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('ACTIVE','INACTIVE','LOCKED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be ACTIVE, INACTIVE or LOCKED.';
        LEAVE proc_label;
    END IF;

    SELECT status INTO v_old_status FROM Users WHERE user_id = p_user_id AND isdeleted = 0;

    IF v_old_status IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Users SET status = p_status WHERE user_id = p_user_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), COALESCE(p_actor_id, p_user_id), 'STATUS_CHANGE', 'Users', p_user_id,
            JSON_OBJECT('status', v_old_status), JSON_OBJECT('status', p_status), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_User_Delete
-- Soft delete only.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_User_Delete $$
CREATE PROCEDURE usp_User_Delete (
    IN  p_user_id        BIGINT UNSIGNED,
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

    IF p_user_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'user_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'User not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Users
    SET isdeleted = 1,
        status = 'INACTIVE'
    WHERE user_id = p_user_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), COALESCE(p_actor_id, p_user_id), 'DELETE', 'Users', p_user_id,
            NULL, NULL, NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Otp_Create
-- Generates/stores an OTP record. The actual OTP code and its hash are
-- computed in C# (proc only stores the hash — never the plaintext code).
-- Any previously active (unused, unexpired) OTP for the same
-- target+purpose is invalidated first, so only one code is valid at a time.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Otp_Create $$
CREATE PROCEDURE usp_Otp_Create (
    IN  p_target_type      VARCHAR(20),   -- USER / CLIENT
    IN  p_target_id        BIGINT UNSIGNED,
    IN  p_destination      VARCHAR(150),  -- phone/email the code was sent to — must be on-file value, not user-supplied, for account-linking flows
    IN  p_purpose          VARCHAR(20),   -- LOGIN / REGISTER / ATTACH_LOGIN / RESET_PASSWORD
    IN  p_otp_code_hash    VARCHAR(255),
    IN  p_expires_minutes  INT,
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500),
    OUT o_otp_id           BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_target_type IS NULL OR p_target_id IS NULL OR p_destination IS NULL
       OR p_purpose IS NULL OR p_otp_code_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'target_type, target_id, destination, purpose and otp_code_hash are required.';
        LEAVE proc_label;
    END IF;

    IF p_target_type NOT IN ('USER','CLIENT') THEN
        SET o_result_code = 1;
        SET o_result_message = 'target_type must be USER or CLIENT.';
        LEAVE proc_label;
    END IF;

    IF p_expires_minutes IS NULL OR p_expires_minutes < 1 THEN
        SET p_expires_minutes = 5;
    END IF;

    START TRANSACTION;

    -- Invalidate any prior active OTP for this target+purpose
    UPDATE OtpVerifications
    SET is_used = 1
    WHERE target_type = p_target_type
      AND target_id = p_target_id
      AND purpose = p_purpose
      AND is_used = 0;

    INSERT INTO OtpVerifications (target_type, target_id, destination, purpose,
                                   otp_code_hash, expires_on, is_used, attempt_count, created_on)
    VALUES (p_target_type, p_target_id, p_destination, p_purpose,
            p_otp_code_hash, DATE_ADD(NOW(), INTERVAL p_expires_minutes MINUTE), 0, 0, NOW());

    SET o_otp_id = LAST_INSERT_ID();

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Otp_Verify
-- Verifies a submitted OTP hash against the active record for the
-- target+purpose. Increments attempt_count on mismatch (max 5 attempts),
-- marks is_used on success, and logs a security audit entry on success.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Otp_Verify $$
CREATE PROCEDURE usp_Otp_Verify (
    IN  p_target_type    VARCHAR(20),
    IN  p_target_id      BIGINT UNSIGNED,
    IN  p_purpose        VARCHAR(20),
    IN  p_otp_code_hash  VARCHAR(255),
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_otp_id         BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_otp_id BIGINT UNSIGNED;
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_attempt_count TINYINT UNSIGNED;
    DECLARE v_expires_on DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_target_type IS NULL OR p_target_id IS NULL OR p_purpose IS NULL OR p_otp_code_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'target_type, target_id, purpose and otp_code_hash are required.';
        LEAVE proc_label;
    END IF;

    SELECT otp_id, otp_code_hash, attempt_count, expires_on
    INTO v_otp_id, v_stored_hash, v_attempt_count, v_expires_on
    FROM OtpVerifications
    WHERE target_type = p_target_type
      AND target_id = p_target_id
      AND purpose = p_purpose
      AND is_used = 0
    ORDER BY created_on DESC
    LIMIT 1;

    IF v_otp_id IS NULL THEN
        SET o_result_code = 4;
        SET o_result_message = 'No active OTP found — request a new code.';
        LEAVE proc_label;
    END IF;

    IF v_expires_on < NOW() THEN
        SET o_result_code = 4;
        SET o_result_message = 'OTP has expired — request a new code.';
        LEAVE proc_label;
    END IF;

    IF v_attempt_count >= 5 THEN
        SET o_result_code = 4;
        SET o_result_message = 'Too many failed attempts — request a new code.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    IF v_stored_hash <> p_otp_code_hash THEN
        UPDATE OtpVerifications SET attempt_count = attempt_count + 1 WHERE otp_id = v_otp_id;
        COMMIT;
        SET o_result_code = 4;
        SET o_result_message = 'Incorrect OTP.';
        LEAVE proc_label;
    END IF;

    UPDATE OtpVerifications SET is_used = 1 WHERE otp_id = v_otp_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (p_target_type, p_target_id, 'OTP_VERIFIED', 'OtpVerifications', v_otp_id,
            NULL, JSON_OBJECT('purpose', p_purpose), NOW());

    COMMIT;
    SET o_otp_id = v_otp_id;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ChannelServiceAccount_GetByChannel
-- Fetches the service-account credentials/role for USSD, WhatsApp, or
-- Website-guest so the API layer can authenticate the channel request
-- (compare api_key_hash, check allowed_ip_range) before processing it.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ChannelServiceAccount_GetByChannel $$
CREATE PROCEDURE usp_ChannelServiceAccount_GetByChannel (
    IN  p_channel VARCHAR(20),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_channel IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ChannelServiceAccounts WHERE channel = p_channel AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Channel service account not found or inactive.';
        LEAVE proc_label;
    END IF;

    SELECT csa.service_account_id, csa.channel, csa.api_key_hash, csa.allowed_ip_range,
           csa.role_id, r.role_code
    FROM ChannelServiceAccounts csa
    JOIN Roles r ON r.role_id = csa.role_id
    WHERE csa.channel = p_channel AND csa.is_active = 1;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ChannelServiceAccount_Create
-- SuperAdmin-only (MANAGE_CHANNELS): registers a brand-new channel
-- integration. The API layer generates the plaintext key and hashes it
-- BEFORE calling this proc - the proc, like every other row in this
-- table, only ever sees/stores the hash, never the plaintext. role_id is
-- always resolved to CS (CHANNEL_SERVICE) here, not accepted as a
-- parameter - every channel account is that one role by definition.
-- channel is no longer constrained to a fixed enum at the DB level (the
-- old chk_channel_accounts_channel CHECK constraint was dropped) - the
-- API layer validates the shape (uppercase, alphanumeric/underscore) so
-- this stays deliberate rather than becoming free-for-all text, but new
-- channel names don't need a schema migration to add anymore.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ChannelServiceAccount_Create $$
CREATE PROCEDURE usp_ChannelServiceAccount_Create (
    IN  p_channel            VARCHAR(20),
    IN  p_api_key_hash       VARCHAR(255),
    IN  p_allowed_ip_range   VARCHAR(100),
    IN  p_actor_id           BIGINT UNSIGNED,
    OUT o_result_code        INT,
    OUT o_result_message     VARCHAR(500),
    OUT o_service_account_id BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE v_role_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_channel IS NULL OR p_api_key_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'channel and api_key_hash are required.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM ChannelServiceAccounts WHERE channel = p_channel) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A channel account already exists for this channel — use Regenerate Key instead.';
        LEAVE proc_label;
    END IF;

    SELECT role_id INTO v_role_id FROM Roles WHERE role_code = 'CS' AND is_active = 1;

    IF v_role_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'CHANNEL_SERVICE role not found or inactive.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO ChannelServiceAccounts (channel, api_key_hash, allowed_ip_range, role_id, is_active)
    VALUES (p_channel, p_api_key_hash, p_allowed_ip_range, v_role_id, 1);

    SET o_service_account_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'ChannelServiceAccounts', o_service_account_id,
            NULL, JSON_OBJECT('channel', p_channel), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ChannelServiceAccount_GetList
-- SuperAdmin-only (MANAGE_CHANNELS) admin listing - never returns
-- api_key_hash, same reasoning Users/Clients listings never return
-- password_hash.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ChannelServiceAccount_GetList $$
CREATE PROCEDURE usp_ChannelServiceAccount_GetList (
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    SELECT csa.service_account_id, csa.channel, csa.allowed_ip_range, csa.is_active, r.role_code
    FROM ChannelServiceAccounts csa
    JOIN Roles r ON r.role_id = csa.role_id
    ORDER BY csa.channel ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ChannelServiceAccount_SetStatus
-- SuperAdmin-only (MANAGE_CHANNELS): activates/deactivates a channel
-- account - same soft-disable shape used elsewhere (is_active flag, no
-- hard delete since Purchases/QuoteRequests may reference this account
-- via channel_service_account_id).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ChannelServiceAccount_SetStatus $$
CREATE PROCEDURE usp_ChannelServiceAccount_SetStatus (
    IN  p_service_account_id BIGINT UNSIGNED,
    IN  p_is_active          TINYINT(1),
    IN  p_actor_id           BIGINT UNSIGNED,
    OUT o_result_code        INT,
    OUT o_result_message     VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old_is_active TINYINT(1);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_service_account_id IS NULL OR p_is_active IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'service_account_id and is_active are required.';
        LEAVE proc_label;
    END IF;

    SELECT is_active INTO v_old_is_active FROM ChannelServiceAccounts WHERE service_account_id = p_service_account_id;

    IF v_old_is_active IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Channel account not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE ChannelServiceAccounts SET is_active = p_is_active WHERE service_account_id = p_service_account_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'ChannelServiceAccounts', p_service_account_id,
            JSON_OBJECT('is_active', v_old_is_active), JSON_OBJECT('is_active', p_is_active), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_ChannelServiceAccount_RegenerateKey
-- SuperAdmin-only (MANAGE_CHANNELS): issues a new key for an EXISTING
-- channel (e.g. rotating a compromised key, or re-provisioning a row
-- whose key was lost) without touching the channel name itself. Same
-- "API layer hashes before calling" rule as Create.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ChannelServiceAccount_RegenerateKey $$
CREATE PROCEDURE usp_ChannelServiceAccount_RegenerateKey (
    IN  p_service_account_id BIGINT UNSIGNED,
    IN  p_new_api_key_hash   VARCHAR(255),
    IN  p_actor_id           BIGINT UNSIGNED,
    OUT o_result_code        INT,
    OUT o_result_message     VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_service_account_id IS NULL OR p_new_api_key_hash IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'service_account_id and new_api_key_hash are required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ChannelServiceAccounts WHERE service_account_id = p_service_account_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Channel account not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE ChannelServiceAccounts SET api_key_hash = p_new_api_key_hash WHERE service_account_id = p_service_account_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'ChannelServiceAccounts', p_service_account_id,
            NULL, JSON_OBJECT('action', 'key_regenerated'), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
