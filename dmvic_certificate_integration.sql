-- ============================================================
-- D-MVIC / NTSA official motor certificate integration (live DB delta)
-- 1. Underwriters.dmvic_code = 49 for Definite Assurance (NTSA member id,
--    from BIMADLINE insurance_company.memberID)
-- 2. Purchases gains ntsa_certificate_no / ntsa_transaction_no / ntsa_issued_on
-- 3. VehicleCertificateDocuments (mirrors BIMADLINE d_insurance_cert_documents)
-- 4. usp_Purchase_GetById exposes the NTSA fields
-- 5. usp_Purchase_GetDmvicData - payload builder for the issuance call
-- 6. usp_Purchase_SaveDmvicResult - persists actualCNo/TransactionNo + doc
-- 7. usp_Purchase_GetVehicleCertificateDocument - latest official doc fetch
-- (purchase_completion.sql covers fresh installs - this file safely
--  advances an existing database that already ran it.)
-- ============================================================

USE insurance_platform;

UPDATE Underwriters SET dmvic_code = '49' WHERE underwriter_id = 4;

SET @col_exists := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Purchases'
      AND COLUMN_NAME = 'ntsa_certificate_no'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE Purchases
        ADD COLUMN ntsa_certificate_no VARCHAR(100) NULL AFTER certificate_number,
        ADD COLUMN ntsa_transaction_no VARCHAR(100) NULL AFTER ntsa_certificate_no,
        ADD COLUMN ntsa_issued_on DATETIME NULL AFTER ntsa_transaction_no',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS VehicleCertificateDocuments (
    cert_doc_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_id       BIGINT UNSIGNED NOT NULL,
    transaction_no    VARCHAR(100) NULL,
    cert_no           VARCHAR(100) NULL,
    email             VARCHAR(150) NULL,
    cert_download_url VARCHAR(1000) NULL,
    cert_data         LONGTEXT NULL,
    cert_generated    TINYINT(1) NOT NULL DEFAULT 0,
    cert_status       VARCHAR(20) NULL,
    policy_number     VARCHAR(150) NULL,
    created_on        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vcd_purchase (purchase_id)
);

DROP PROCEDURE IF EXISTS usp_Purchase_GetById;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_GetById (
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

    SELECT pu.purchase_id, pu.product_id, pr.code AS product_code, pr.name AS product_name, pu.client_id,
           c.full_name AS client_name, c.id_no AS client_id_no, c.phone AS client_phone, c.email AS client_email,
           pu.purchased_by_user_id, pu.channel_service_account_id, pu.underwriter_id,
           u.name AS underwriter_name, pu.quote_offer_id, pu.premium_amount, pu.period_id,
           per.name AS period_name, pu.start_date, pu.end_date, pu.policy_number,
           pu.payment_status, pu.status, pu.created_on,
           pu.certificate_status, pu.cert_generated_on, pu.certificate_number,
           pu.ntsa_certificate_no, pu.ntsa_transaction_no, pu.ntsa_issued_on,
           v.reg_no AS vehicle_reg_no, v.make AS vehicle_make, v.model AS vehicle_model
    FROM Purchases pu
    JOIN Products pr ON pr.product_id = pu.product_id
    JOIN Underwriters u ON u.underwriter_id = pu.underwriter_id
    JOIN Periods per ON per.period_id = pu.period_id
    LEFT JOIN Clients c ON c.client_id = pu.client_id
    LEFT JOIN VehiclePurchaseSnapshot vps ON vps.purchase_id = pu.purchase_id
    LEFT JOIN Vehicles v ON v.vehicle_id = vps.vehicle_id
    WHERE pu.purchase_id = p_purchase_id
    LIMIT 1;

    SELECT snapshot_id, vehicle_id, vehicle_value, tonnage, licensedtocarry, antitheft, risk, amount
    FROM VehiclePurchaseSnapshot
    WHERE purchase_id = p_purchase_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;

-- Builds the D-MVIC issuance payload fields straight from the purchase's
-- joined client/vehicle/underwriter. LEFT JOINs on purpose: non-Motor
-- purchases (or missing vehicle data) come back with NULLs and the caller
-- decides to skip rather than the proc erroring.
DROP PROCEDURE IF EXISTS usp_Purchase_GetDmvicData;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_GetDmvicData (
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

    SELECT COUNT(*) INTO @row_count FROM Purchases WHERE purchase_id = p_purchase_id;
    IF @row_count = 0 THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    SELECT p.purchase_id, p.policy_number, p.start_date, p.end_date, p.premium_amount,
           p.certificate_number, p.ntsa_certificate_no, p.ntsa_transaction_no,
           c.full_name AS policyholder, c.phone AS client_phone, c.email AS client_email, c.kra_pin,
           v.reg_no, v.make, v.model, v.chassis_no, v.engine_no, v.yearofmanufacture,
           v.p_bodytype, v.vehicle_type,
           vsp.vehicle_value, vsp.licensedtocarry,
           u.dmvic_code AS member_company_id, u.name AS underwriter_name
    FROM Purchases p
    JOIN Underwriters u ON u.underwriter_id = p.underwriter_id
    JOIN Clients c ON c.client_id = p.client_id
    LEFT JOIN VehiclePurchaseSnapshot vsp ON vsp.purchase_id = p.purchase_id
    LEFT JOIN Vehicles v ON v.vehicle_id = vsp.vehicle_id
    WHERE p.purchase_id = p_purchase_id
    LIMIT 1;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;

-- Persists a successful issuance: stamps the purchase with the NTSA cert
-- number + transaction no and records the official document row.
DROP PROCEDURE IF EXISTS usp_Purchase_SaveDmvicResult;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_SaveDmvicResult (
    IN  p_purchase_id BIGINT UNSIGNED,
    IN  p_ntsa_certificate_no VARCHAR(100),
    IN  p_ntsa_transaction_no VARCHAR(100),
    IN  p_email VARCHAR(150),
    IN  p_cert_download_url VARCHAR(1000),
    IN  p_cert_data LONGTEXT,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF p_purchase_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id is required.';
        LEAVE proc_label;
    END IF;

    IF EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id AND ntsa_certificate_no = p_ntsa_certificate_no) THEN
        SET o_result_code = 3;
        SET o_result_message = 'D-MVIC certificate already recorded for this purchase.';
        LEAVE proc_label;
    END IF;

    UPDATE Purchases
    SET ntsa_certificate_no = p_ntsa_certificate_no,
        ntsa_transaction_no = p_ntsa_transaction_no,
        ntsa_issued_on = NOW()
    WHERE purchase_id = p_purchase_id;

    INSERT INTO VehicleCertificateDocuments
        (purchase_id, transaction_no, cert_no, email, cert_download_url, cert_data,
         cert_generated, cert_status, policy_number)
    SELECT p.purchase_id, p_ntsa_transaction_no, p_ntsa_certificate_no, p_email,
           p_cert_download_url, p_cert_data, 1, 'ACTIVE', p.policy_number
    FROM Purchases p
    WHERE p.purchase_id = p_purchase_id;

    SET o_result_code = 0;
    SET o_result_message = 'D-MVIC certificate recorded.';
END$$
DELIMITER ;

-- Latest official certificate document for a purchase (for the certificate
-- page / download endpoint).
DROP PROCEDURE IF EXISTS usp_Purchase_GetVehicleCertificateDocument;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_GetVehicleCertificateDocument (
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

    IF NOT EXISTS (SELECT 1 FROM VehicleCertificateDocuments WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'No official certificate document for this purchase.';
        LEAVE proc_label;
    END IF;

    SELECT cert_doc_id, purchase_id, transaction_no, cert_no, email, cert_download_url,
           cert_data, cert_generated, cert_status, policy_number, created_on
    FROM VehicleCertificateDocuments
    WHERE purchase_id = p_purchase_id
    ORDER BY cert_doc_id DESC
    LIMIT 1;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;