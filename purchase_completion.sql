-- ============================================================
-- Purchase payment + certificate completion feature
-- 1. Add certificate tracking columns to Purchases
-- 2. Rebuild usp_Purchase_GetTimeline with account_number + cert info
-- 3. Create usp_Purchase_CompleteCert (retry / background-service path)
-- ============================================================

ALTER TABLE Purchases
    ADD COLUMN certificate_status VARCHAR(20) NOT NULL DEFAULT 'NOT_GENERATED' AFTER payment_status,
    ADD COLUMN cert_generated_on DATETIME NULL AFTER certificate_status;

DROP PROCEDURE IF EXISTS usp_Purchase_GetTimeline;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_GetTimeline(
    IN p_purchase_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
    ELSE
        SET o_result_code = 0;
        SET o_result_message = 'Success';

        (SELECT
            'PURCHASE_SUMMARY' AS event_type,
            1 AS step_order,
            CAST(p.purchase_id AS SIGNED) AS ref_id,
            p.created_on AS event_time,
            JSON_OBJECT(
                'purchase_id', p.purchase_id,
                'policy_number', p.policy_number,
                'premium_amount', p.premium_amount,
                'payment_status', p.payment_status,
                'status', p.status,
                'certificate_status', p.certificate_status,
                'cert_generated_on', CASE WHEN p.cert_generated_on IS NOT NULL THEN DATE_FORMAT(p.cert_generated_on, '%Y-%m-%d %H:%i:%s') ELSE NULL END,
                'account_number', CASE
                    WHEN v.reg_no IS NOT NULL THEN CONCAT(COALESCE(v.reg_no, 'VEH'), '#', LPAD(p.purchase_id, 3, '0'))
                    ELSE CONCAT(COALESCE(c.id_no, 'CLI'), '#', LPAD(p.purchase_id, 3, '0'))
                END,
                'start_date', DATE_FORMAT(p.start_date, '%Y-%m-%d'),
                'end_date', DATE_FORMAT(p.end_date, '%Y-%m-%d'),
                'created_on', DATE_FORMAT(p.created_on, '%Y-%m-%d %H:%i:%s'),
                'client_name', c.full_name,
                'client_id_no', c.id_no,
                'client_phone', c.phone,
                'client_email', c.email,
                'product_name', pr.name,
                'product_code', pr.code,
                'underwriter_name', u.name,
                'underwriter_code', u.code,
                'created_by_name', usr.full_name
            ) AS event_data
        FROM Purchases p
        LEFT JOIN Clients c ON c.client_id = p.client_id
        LEFT JOIN Products pr ON pr.product_id = p.product_id
        LEFT JOIN Underwriters u ON u.underwriter_id = p.underwriter_id
        LEFT JOIN Users usr ON usr.user_id = p.purchased_by_user_id
        LEFT JOIN VehiclePurchaseSnapshot vps ON vps.purchase_id = p.purchase_id
        LEFT JOIN Vehicles v ON v.vehicle_id = vps.vehicle_id
        WHERE p.purchase_id = p_purchase_id)

        UNION ALL

        (SELECT
            CONCAT('PAYMENT_', pay.status) AS event_type,
            2 AS step_order,
            CAST(pay.payment_id AS SIGNED) AS ref_id,
            pay.initiated_on AS event_time,
            JSON_OBJECT(
                'payment_id', pay.payment_id,
                'amount', pay.amount,
                'method', pay.method,
                'payer_phone', pay.payer_phone,
                'transaction_reference', pay.transaction_reference,
                'status', pay.status,
                'initiated_on', DATE_FORMAT(pay.initiated_on, '%Y-%m-%d %H:%i:%s'),
                'completed_on', CASE WHEN pay.completed_on IS NOT NULL THEN DATE_FORMAT(pay.completed_on, '%Y-%m-%d %H:%i:%s') ELSE NULL END
            ) AS event_data
        FROM Payments pay
        WHERE pay.purchase_id = p_purchase_id)

        UNION ALL

        (SELECT
            'VEHICLE' AS event_type,
            3 AS step_order,
            CAST(vps.snapshot_id AS SIGNED) AS ref_id,
            vps.created_on AS event_time,
            JSON_OBJECT(
                'snapshot_id', vps.snapshot_id,
                'vehicle_value', vps.vehicle_value,
                'tonnage', vps.tonnage,
                'licensedtocarry', vps.licensedtocarry,
                'antitheft', vps.antitheft,
                'risk', vps.risk,
                'amount', vps.amount,
                'make', v.make,
                'model', v.model,
                'reg_no', v.reg_no,
                'chassis_no', v.chassis_no,
                'engine_no', v.engine_no,
                'yearofmanufacture', v.yearofmanufacture,
                'vehicle_type', v.vehicle_type,
                'p_bodytype', v.p_bodytype,
                'fueltype', v.fueltype,
                'cubiccapacity', v.cubiccapacity,
                'color', v.color
            ) AS event_data
        FROM VehiclePurchaseSnapshot vps
        LEFT JOIN Vehicles v ON v.vehicle_id = vps.vehicle_id
        WHERE vps.purchase_id = p_purchase_id
        LIMIT 1)

        UNION ALL

        (SELECT
            al.action AS event_type,
            4 AS step_order,
            CAST(al.audit_id AS SIGNED) AS ref_id,
            al.created_on AS event_time,
            JSON_OBJECT(
                'audit_id', al.audit_id,
                'actor_type', al.actor_type,
                'actor_id', al.actor_id,
                'actor_name', CASE
                    WHEN al.actor_type = 'USER' THEN (SELECT full_name FROM Users WHERE user_id = al.actor_id)
                    ELSE NULL
                END,
                'action', al.action,
                'entity', al.entity,
                'entity_id', al.entity_id,
                'old_value', al.old_value,
                'new_value', al.new_value
            ) AS event_data
        FROM AuditLog al
        WHERE (al.entity = 'Purchases' AND al.entity_id = p_purchase_id)
           OR (al.entity = 'Payments' AND al.entity_id IN (SELECT payment_id FROM Payments WHERE purchase_id = p_purchase_id))
        ORDER BY al.created_on ASC)

        UNION ALL

        (SELECT
            'RELATED_PURCHASE' AS event_type,
            5 AS step_order,
            CAST(p2.purchase_id AS SIGNED) AS ref_id,
            p2.created_on AS event_time,
            JSON_OBJECT(
                'purchase_id', p2.purchase_id,
                'policy_number', p2.policy_number,
                'premium_amount', p2.premium_amount,
                'payment_status', p2.payment_status,
                'status', p2.status,
                'created_on', DATE_FORMAT(p2.created_on, '%Y-%m-%d %H:%i:%s'),
                'underwriter_name', u2.name
            ) AS event_data
        FROM Purchases p2
        LEFT JOIN Underwriters u2 ON u2.underwriter_id = p2.underwriter_id
        WHERE p2.client_id = (SELECT client_id FROM Purchases WHERE purchase_id = p_purchase_id)
          AND p2.purchase_id != p_purchase_id
        ORDER BY p2.created_on DESC
        LIMIT 10)

        ORDER BY step_order, event_time;
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- usp_Purchase_CompleteCert - marks a PAID purchase's certificate
-- as generated. This is the exact code path the retry button calls
-- synchronously AND the future background service will invoke once
-- payment is confirmed - one shared completion routine.
-- ============================================================
DROP PROCEDURE IF EXISTS usp_Purchase_CompleteCert;
DELIMITER $$
CREATE PROCEDURE usp_Purchase_CompleteCert(
    IN p_purchase_id BIGINT UNSIGNED,
    IN p_actor_type VARCHAR(20),
    IN p_actor_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_payment_status VARCHAR(20);
    DECLARE v_cert_status VARCHAR(20);
    DECLARE v_actor_type VARCHAR(20);

    SELECT payment_status, certificate_status INTO v_payment_status, v_cert_status
    FROM Purchases WHERE purchase_id = p_purchase_id;

    IF v_payment_status IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
    ELSEIF v_payment_status <> 'PAID' THEN
        SET o_result_code = 1;
        SET o_result_message = CONCAT('Certificate cannot be generated - payment is ', v_payment_status, '. Mark the payment as paid first.');
    ELSEIF v_cert_status = 'GENERATED' THEN
        SET o_result_code = 1;
        SET o_result_message = 'Certificate has already been generated for this purchase.';
    ELSE
        -- AuditLog.actor_type is CHECK-constrained to USER/CLIENT/CHANNEL_SERVICE
        -- (chk_audit_actor_type). A background service has no login identity, so
        -- normalize any unrecognised caller to USER - same idea as the API's own
        -- CurrentRoleCode->actor_type mapping, just defensive against direct
        -- background-service invocation.
        IF p_actor_type IN ('USER','CLIENT','CHANNEL_SERVICE') THEN
            SET v_actor_type = p_actor_type;
        ELSE
            SET v_actor_type = 'USER';
        END IF;

        UPDATE Purchases
        SET certificate_status = 'GENERATED',
            cert_generated_on = NOW()
        WHERE purchase_id = p_purchase_id;

        INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
        VALUES (v_actor_type, p_actor_id, 'COMPLETE', 'Purchases', p_purchase_id,
                JSON_OBJECT('certificate_status', v_cert_status),
                JSON_OBJECT('certificate_status', 'GENERATED'),
                NOW());

        SET o_result_code = 0;
        SET o_result_message = 'Payment received successfully - your certificate will be emailed to you shortly.';
    END IF;
END$$
DELIMITER ;