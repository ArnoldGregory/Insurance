-- Client certificate self-service lookup for the website's "Get your
-- certificate" page (return visitors with no browser session). Resolves a
-- purchase from nothing but the policy number + the buyer's phone number -
-- the phone match is the only guard, and a mismatch returns the SAME
-- generic "not found" as an unknown policy so the endpoint can't be used
-- to probe for policy numbers.
--
-- Idempotent: DROP IF EXISTS first, safe to re-run on any database
-- together with server_setup_migration.sql / offer_status_migrations.sql.

DROP PROCEDURE IF EXISTS usp_Purchase_LookupClientCertificate;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_LookupClientCertificate (
    IN  p_policy_number     VARCHAR(100),
    IN  p_phone             VARCHAR(50),
    OUT o_purchase_id       BIGINT UNSIGNED,
    OUT o_result_code       INT,
    OUT o_result_message    VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_phone_in VARCHAR(20);

    IF p_policy_number IS NULL OR LENGTH(TRIM(p_policy_number)) = 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'Policy number is required.';
        LEAVE proc_label;
    END IF;

    IF p_phone IS NULL OR LENGTH(TRIM(p_phone)) = 0 THEN
        SET o_result_code = 2;
        SET o_result_message = 'Phone number is required.';
        LEAVE proc_label;
    END IF;

    -- Normalize the input phone to bare digits - "0712 345 678",
    -- "+254712345678" and "254712345678" all strip down the same way.
    SET v_phone_in = REPLACE(REPLACE(REPLACE(REPLACE(p_phone, '+', ''), '-', ''), ' ', ''), '(', '');
    SET v_phone_in = REPLACE(v_phone_in, ')', '');
    IF LENGTH(v_phone_in) < 9 THEN
        SET o_result_code = 2;
        SET o_result_message = 'Phone number is required.';
        LEAVE proc_label;
    END IF;

    -- Match by the LAST 9 digits against the policy's own client phone -
    -- the digit span common to every Kenyan mobile spelling (0-prefixed,
    -- 254-prefixed or +254-prefixed) without trying to outsmart formats.
    IF NOT EXISTS (
        SELECT 1
        FROM Purchases p
        JOIN Clients c ON c.client_id = p.client_id
        WHERE UPPER(TRIM(p.policy_number)) = UPPER(TRIM(p_policy_number))
          AND LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone, '+', ''), '-', ''), ' ', ''), '(', ''), ')', '')) >= 9
          AND RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone, '+', ''), '-', ''), ' ', ''), '(', ''), ')', ''), 9)
              = RIGHT(v_phone_in, 9)
    ) THEN
        -- One generic failure for an unknown policy AND a wrong phone, so
        -- the endpoint never reveals which one didn't line up.
        SET o_result_code = 3;
        SET o_result_message = 'No policy found for that policy number and phone number.';
        LEAVE proc_label;
    END IF;

    -- Most recent matching purchase wins (a policy number should be unique,
    -- but never assume) - the caller renders whatever state it is in
    -- (payment pending, certificate generating, or generated).
    SELECT p.purchase_id
    INTO o_purchase_id
    FROM Purchases p
    JOIN Clients c ON c.client_id = p.client_id
    WHERE UPPER(TRIM(p.policy_number)) = UPPER(TRIM(p_policy_number))
      AND LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone, '+', ''), '-', ''), ' ', ''), '(', ''), ')', '')) >= 9
      AND RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone, '+', ''), '-', ''), ' ', ''), '(', ''), ')', ''), 9)
          = RIGHT(v_phone_in, 9)
    ORDER BY p.purchase_id DESC
    LIMIT 1;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END$$
DELIMITER ;