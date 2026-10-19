-- =====================================================================
-- Underwriter certificate integrations (DirectLine / AMACO / Definite)
-- =====================================================================
-- Mirrors how the live BIMADLINE platform works with insurers that do NOT
-- issue through our own DMVIC intermediary call:
--   * DirectLine : we POST the cover to SCAPI (interface DIRECTLINE,
--                  request_type DirectLineCertificateGeneration); DirectLine
--                  later calls us back with policy + cert number + PDF link.
--   * AMACO /
--     Definite   : the insurer issues on its side and calls us back with the
--                  certificate (Definite echoes our ExternalRef; AMACO only
--                  sends its PolicyNumber, so we also match on policy number).
--
-- Routing (which underwriter uses which path) is configuration, not schema:
-- see UnderwriterIntegrations in appsettings.json. With every integration
-- disabled (the default) nothing changes - all purchases keep using DMVIC.
--
-- On a successful callback the certificate is recorded through the existing
-- usp_Purchase_SaveDmvicResult, so it shows up exactly like an NTSA/DMVIC
-- certificate (Purchases.ntsa_certificate_no + VehicleCertificateDocuments).
--
-- Idempotent: safe to re-run.
-- =====================================================================
USE insurance_platform;

CREATE TABLE IF NOT EXISTS UnderwriterCertificateRequests (
    request_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    purchase_id       BIGINT UNSIGNED NOT NULL,
    integration       VARCHAR(20)  NOT NULL COMMENT 'DIRECTLINE | AMACO | DEFINITE',
    external_ref      VARCHAR(50)  NOT NULL COMMENT 'Reference we send / the insurer echoes back',
    status            VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING | POSTED | AWAITING_CALLBACK | ISSUED | FAILED',
    request_payload   LONGTEXT     NULL,
    response_payload  LONGTEXT     NULL,
    callback_payload  LONGTEXT     NULL,
    cert_no           VARCHAR(100) NULL,
    policy_no         VARCHAR(100) NULL,
    cert_url          VARCHAR(1000) NULL,
    error_message     VARCHAR(500) NULL,
    created_on        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on        DATETIME     NULL,
    PRIMARY KEY (request_id),
    UNIQUE KEY uq_ucr_external_ref (integration, external_ref),
    INDEX idx_ucr_purchase (purchase_id, status),
    CONSTRAINT fk_ucr_purchase FOREIGN KEY (purchase_id) REFERENCES Purchases(purchase_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ---------------------------------------------------------------------
-- Everything an insurer integration needs about a purchase (superset of
-- usp_Purchase_GetDmvicData: adds client id no, cover period length and
-- the underwriter id).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterCert_GetPurchaseData;
DELIMITER $$
CREATE PROCEDURE usp_UnderwriterCert_GetPurchaseData (
    IN  p_purchase_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_purchase_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    SELECT p.purchase_id, p.policy_number, p.start_date, p.end_date, p.premium_amount,
           p.ntsa_certificate_no, p.payment_status,
           per.duration_days,
           c.full_name AS policyholder, c.id_no, c.phone AS client_phone, c.email AS client_email, c.kra_pin,
           v.reg_no, v.make, v.model, v.chassis_no, v.engine_no, v.yearofmanufacture,
           v.p_bodytype, v.vehicle_type, v.cubiccapacity,
           vsp.vehicle_value, vsp.tonnage, vsp.licensedtocarry,
           u.underwriter_id, u.name AS underwriter_name
    FROM Purchases p
    JOIN Underwriters u ON u.underwriter_id = p.underwriter_id
    JOIN Clients c ON c.client_id = p.client_id
    JOIN Periods per ON per.period_id = p.period_id
    LEFT JOIN VehiclePurchaseSnapshot vsp ON vsp.purchase_id = p.purchase_id
    LEFT JOIN Vehicles v ON v.vehicle_id = vsp.vehicle_id
    WHERE p.purchase_id = p_purchase_id
    LIMIT 1;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;


-- ---------------------------------------------------------------------
-- Opens a request. Refuses (code 3) when the purchase already has an
-- issued certificate or an open request for the same integration, so the
-- three certificate triggers (callback / retry / worker) never double-post.
-- A FAILED request may be retried: it is replaced by the new one.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterCert_CreateRequest;
DELIMITER $$
CREATE PROCEDURE usp_UnderwriterCert_CreateRequest (
    IN  p_purchase_id     BIGINT UNSIGNED,
    IN  p_integration     VARCHAR(20),
    IN  p_external_ref    VARCHAR(50),
    IN  p_status          VARCHAR(20),
    IN  p_request_payload LONGTEXT,
    OUT o_result_code     INT,
    OUT o_result_message  VARCHAR(500),
    OUT o_request_id      BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error creating the underwriter certificate request.';
    END;

    SET o_request_id = NULL;

    IF p_purchase_id IS NULL OR p_integration IS NULL OR p_external_ref IS NULL OR p_external_ref = '' THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id, integration and external_ref are required.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id
                 AND ntsa_certificate_no IS NOT NULL AND ntsa_certificate_no <> '') THEN
        SET o_result_code = 3;
        SET o_result_message = 'A certificate is already recorded for this purchase.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM UnderwriterCertificateRequests
                WHERE purchase_id = p_purchase_id AND integration = p_integration
                  AND status IN ('PENDING', 'POSTED', 'AWAITING_CALLBACK', 'ISSUED')) THEN
        SET o_result_code = 3;
        SET o_result_message = 'A certificate request is already open for this purchase.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO UnderwriterCertificateRequests
        (purchase_id, integration, external_ref, status, request_payload, created_on)
    VALUES
        (p_purchase_id, p_integration, p_external_ref, COALESCE(p_status, 'PENDING'), p_request_payload, NOW());

    SET o_request_id = LAST_INSERT_ID();

    COMMIT;

    SET o_result_code = 0;
    SET o_result_message = 'Certificate request created.';
END$$
DELIMITER ;


-- ---------------------------------------------------------------------
-- Updates a request's status / outcome by its external reference.
-- NULL inputs leave the existing value untouched.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterCert_UpdateRequest;
DELIMITER $$
CREATE PROCEDURE usp_UnderwriterCert_UpdateRequest (
    IN  p_request_id       BIGINT UNSIGNED,
    IN  p_status           VARCHAR(20),
    IN  p_response_payload LONGTEXT,
    IN  p_callback_payload LONGTEXT,
    IN  p_cert_no          VARCHAR(100),
    IN  p_policy_no        VARCHAR(100),
    IN  p_cert_url         VARCHAR(1000),
    IN  p_error_message    VARCHAR(500),
    OUT o_result_code      INT,
    OUT o_result_message   VARCHAR(500)
)
proc_label: BEGIN
    IF NOT EXISTS (SELECT 1 FROM UnderwriterCertificateRequests WHERE request_id = p_request_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Certificate request not found.';
        LEAVE proc_label;
    END IF;

    UPDATE UnderwriterCertificateRequests
    SET status           = COALESCE(p_status, status),
        response_payload = COALESCE(p_response_payload, response_payload),
        callback_payload = COALESCE(p_callback_payload, callback_payload),
        cert_no          = COALESCE(p_cert_no, cert_no),
        policy_no        = COALESCE(p_policy_no, policy_no),
        cert_url         = COALESCE(p_cert_url, cert_url),
        error_message    = COALESCE(p_error_message, error_message),
        updated_on       = NOW()
    WHERE request_id = p_request_id;

    SET o_result_code = 0;
    SET o_result_message = 'Certificate request updated.';
END$$
DELIMITER ;


-- ---------------------------------------------------------------------
-- Finds the request an insurer callback belongs to: by our external
-- reference first, then (AMACO) by the purchase's policy number.
-- Most recent matching request wins.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_UnderwriterCert_FindForCallback;
DELIMITER $$
CREATE PROCEDURE usp_UnderwriterCert_FindForCallback (
    IN  p_integration   VARCHAR(20),
    IN  p_external_ref  VARCHAR(50),
    IN  p_policy_number VARCHAR(100),
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_request_id BIGINT UNSIGNED DEFAULT NULL;

    IF p_external_ref IS NOT NULL AND p_external_ref <> '' THEN
        SELECT r.request_id INTO v_request_id
        FROM UnderwriterCertificateRequests r
        WHERE r.integration = p_integration AND r.external_ref = p_external_ref
        ORDER BY r.request_id DESC
        LIMIT 1;
    END IF;

    IF v_request_id IS NULL AND p_policy_number IS NOT NULL AND p_policy_number <> '' THEN
        SELECT r.request_id INTO v_request_id
        FROM UnderwriterCertificateRequests r
        JOIN Purchases p ON p.purchase_id = r.purchase_id
        WHERE r.integration = p_integration
          AND (p.policy_number = p_policy_number OR r.policy_no = p_policy_number)
        ORDER BY r.request_id DESC
        LIMIT 1;
    END IF;

    IF v_request_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'No certificate request matches this callback.';
        LEAVE proc_label;
    END IF;

    SELECT r.request_id, r.purchase_id, r.integration, r.external_ref, r.status, r.cert_no
    FROM UnderwriterCertificateRequests r
    WHERE r.request_id = v_request_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;
