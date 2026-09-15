-- =====================================================================
-- Insurance Platform — Stored Procedures: PURCHASES / PAYMENTS (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- usp_Purchase_Create is the central proc of the whole platform: it
-- handles both Motor purchases (vehicle_id + snapshot) and manual-quote
-- purchases (quote_offer_id), and accrues agent commission inline when
-- the purchaser is an Agent/Agent_admin — all in one transaction, so a
-- purchase is never recorded without its commission (or vice versa).
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- ---------------------------------------------------------------------
-- usp_Purchase_Create
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_Create $$
CREATE PROCEDURE usp_Purchase_Create (
    IN  p_product_id                BIGINT UNSIGNED,
    IN  p_client_id                 BIGINT UNSIGNED,
    IN  p_purchased_by_user_id      BIGINT UNSIGNED,   -- staff/self; NULL if via channel service account
    IN  p_channel_service_account_id BIGINT UNSIGNED,  -- USSD/WhatsApp/Website-guest; NULL if via a logged-in user
    IN  p_underwriter_id            BIGINT UNSIGNED,
    IN  p_quote_offer_id            BIGINT UNSIGNED,   -- required for MANUAL_QUOTE products; must already be 'SELECTED'
    IN  p_premium_amount            DECIMAL(18,2),
    IN  p_period_id                 BIGINT UNSIGNED,
    IN  p_start_date                DATE,
    IN  p_policy_number             VARCHAR(50),       -- optional; auto-generated if NULL
    IN  p_vehicle_id                BIGINT UNSIGNED,   -- Motor only
    IN  p_vehicle_value             DECIMAL(18,2),      -- Motor snapshot fields
    IN  p_tonnage                   DECIMAL(10,2),
    IN  p_licensedtocarry           BIGINT UNSIGNED,
    IN  p_antitheft                 VARCHAR(50),
    IN  p_risk                      VARCHAR(100),
    IN  p_snapshot_amount           DECIMAL(18,2),
    OUT o_result_code               INT,
    OUT o_result_message            VARCHAR(500),
    OUT o_purchase_id               BIGINT UNSIGNED,
    OUT o_policy_number             VARCHAR(50),
    OUT o_end_date                  DATE,
    OUT o_account_number            VARCHAR(120)
)
proc_label: BEGIN
    DECLARE v_duration_days INT UNSIGNED;
    DECLARE v_role_code VARCHAR(20);
    DECLARE v_rate_percent DECIMAL(5,2);
    DECLARE v_commission_amount DECIMAL(18,2);
    DECLARE v_actor_type VARCHAR(20);
    DECLARE v_actor_id BIGINT UNSIGNED;
    DECLARE v_reg_no VARCHAR(100);
    DECLARE v_client_id_no VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    -- ---- Validation ----
    IF p_product_id IS NULL OR p_client_id IS NULL OR p_underwriter_id IS NULL
       OR p_premium_amount IS NULL OR p_period_id IS NULL OR p_start_date IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'product_id, client_id, underwriter_id, premium_amount, period_id and start_date are required.';
        LEAVE proc_label;
    END IF;

    IF p_premium_amount <= 0 THEN
        SET o_result_code = 1;
        SET o_result_message = 'premium_amount must be greater than zero.';
        LEAVE proc_label;
    END IF;

    IF p_purchased_by_user_id IS NULL AND p_channel_service_account_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'Either purchased_by_user_id or channel_service_account_id is required.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = p_client_id AND isdeleted = 0) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Client not found.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Underwriters WHERE underwriter_id = p_underwriter_id AND is_active = 1) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Underwriter not found or inactive.';
        LEAVE proc_label;
    END IF;

    SELECT duration_days INTO v_duration_days
    FROM Periods WHERE period_id = p_period_id AND is_active = 1;

    IF v_duration_days IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Period not found or inactive.';
        LEAVE proc_label;
    END IF;

    IF p_vehicle_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Vehicles WHERE vehicle_id = p_vehicle_id AND client_id = p_client_id AND isdeleted = 0
    ) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Vehicle not found for this client.';
        LEAVE proc_label;
    END IF;

    IF p_quote_offer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM QuoteOffers WHERE quote_offer_id = p_quote_offer_id AND status = 'SELECTED'
    ) THEN
        SET o_result_code = 4;
        SET o_result_message = 'Quote offer must be selected (usp_QuoteOffer_Select) before it can be purchased.';
        LEAVE proc_label;
    END IF;

    SET o_end_date = DATE_ADD(p_start_date, INTERVAL v_duration_days DAY);
    SET v_actor_type = IF(p_purchased_by_user_id IS NOT NULL, 'USER', 'CHANNEL_SERVICE');
    SET v_actor_id = COALESCE(p_purchased_by_user_id, p_channel_service_account_id);

    START TRANSACTION;

    INSERT INTO Purchases (product_id, client_id, purchased_by_user_id, channel_service_account_id,
                            underwriter_id, quote_offer_id, premium_amount, period_id, start_date, end_date,
                            policy_number, payment_status, status, created_on)
    VALUES (p_product_id, p_client_id, p_purchased_by_user_id, p_channel_service_account_id,
            p_underwriter_id, p_quote_offer_id, p_premium_amount, p_period_id, p_start_date, o_end_date,
            p_policy_number, 'PENDING', 'ACTIVE', NOW());

    SET o_purchase_id = LAST_INSERT_ID();

    -- Auto-generate policy number if the caller didn't supply one
    IF p_policy_number IS NULL THEN
        SET o_policy_number = CONCAT('POL-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(o_purchase_id, 8, '0'));
        UPDATE Purchases SET policy_number = o_policy_number WHERE purchase_id = o_purchase_id;
    ELSE
        SET o_policy_number = p_policy_number;
    END IF;

    -- M-Pesa paybill account reference: "{RegNo}#{purchase_id}" for Motor
    -- (vehicle_id present), else "{ClientIdNo}#{purchase_id}" - always
    -- traceable back to this exact purchase, zero-padded to at least 3
    -- digits (grows past that for purchase_id >= 1000, never truncates).
    -- The actual paybill NUMBER (business short code) is a fixed
    -- environment setting, not purchase-specific data, so it's added by
    -- the API layer (PurchasesController), not computed here.
    IF p_vehicle_id IS NOT NULL THEN
        SELECT reg_no INTO v_reg_no FROM Vehicles WHERE vehicle_id = p_vehicle_id;
        SET o_account_number = CONCAT(COALESCE(v_reg_no, 'VEH'), '#', LPAD(o_purchase_id, 3, '0'));
    ELSE
        SELECT id_no INTO v_client_id_no FROM Clients WHERE client_id = p_client_id;
        SET o_account_number = CONCAT(COALESCE(v_client_id_no, 'CLI'), '#', LPAD(o_purchase_id, 3, '0'));
    END IF;

    -- Motor: freeze the vehicle's variable details as-of this purchase
    IF p_vehicle_id IS NOT NULL THEN
        INSERT INTO VehiclePurchaseSnapshot (vehicle_id, purchase_id, vehicle_value, tonnage,
                                              licensedtocarry, antitheft, risk, amount, created_on)
        VALUES (p_vehicle_id, o_purchase_id, p_vehicle_value, p_tonnage,
                p_licensedtocarry, p_antitheft, p_risk, p_snapshot_amount, NOW());
    END IF;

    -- Manual-quote products: mark the parent quote request as converted
    IF p_quote_offer_id IS NOT NULL THEN
        UPDATE QuoteRequests qr
        JOIN QuoteOffers qo ON qo.quote_request_id = qr.quote_request_id
        SET qr.status = 'CONVERTED'
        WHERE qo.quote_offer_id = p_quote_offer_id;
    END IF;

    -- Commission: only when the purchase was executed by an Agent or
    -- Agent_admin (never for Support_Agent or self-service). Commission
    -- belongs to the agent alone — one flat rate applied to every purchase
    -- they make, regardless of product or underwriter. If the agent has no
    -- rate configured yet, the purchase still completes — commission just
    -- isn't accrued (can be backfilled later via usp_AgentCommission_Accrue
    -- once a rate exists).
    IF p_purchased_by_user_id IS NOT NULL THEN
        SELECT r.role_code INTO v_role_code
        FROM Users u JOIN Roles r ON r.role_id = u.role_id
        WHERE u.user_id = p_purchased_by_user_id;

        IF v_role_code IN ('AG','AA') THEN
            SELECT rate_percent INTO v_rate_percent
            FROM AgentCommissionRates
            WHERE agent_user_id = p_purchased_by_user_id
              AND effective_from <= CURDATE()
              AND (effective_to IS NULL OR effective_to >= CURDATE())
            ORDER BY effective_from DESC
            LIMIT 1;

            IF v_rate_percent IS NOT NULL THEN
                SET v_commission_amount = p_premium_amount * v_rate_percent / 100;

                INSERT INTO AgentCommissions (purchase_id, agent_user_id, rate_percent_applied,
                                               cover_amount, commission_amount, status, created_on)
                VALUES (o_purchase_id, p_purchased_by_user_id, v_rate_percent, p_premium_amount,
                        v_commission_amount, 'ACCRUED', NOW());
            END IF;
        END IF;
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (v_actor_type, v_actor_id, 'CREATE', 'Purchases', o_purchase_id,
            NULL, JSON_OBJECT('client_id', p_client_id, 'product_id', p_product_id,
                              'underwriter_id', p_underwriter_id, 'premium_amount', p_premium_amount,
                              'policy_number', o_policy_number),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetById
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetById $$
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

    SELECT pu.purchase_id, pu.product_id, pr.code AS product_code, pu.client_id,
           pu.purchased_by_user_id, pu.channel_service_account_id, pu.underwriter_id,
           u.name AS underwriter_name, pu.quote_offer_id, pu.premium_amount, pu.period_id,
           per.name AS period_name, pu.start_date, pu.end_date, pu.policy_number,
           pu.payment_status, pu.status, pu.created_on
    FROM Purchases pu
    JOIN Products pr ON pr.product_id = pu.product_id
    JOIN Underwriters u ON u.underwriter_id = pu.underwriter_id
    JOIN Periods per ON per.period_id = pu.period_id
    WHERE pu.purchase_id = p_purchase_id;

    -- Motor purchases also carry a snapshot row
    SELECT snapshot_id, vehicle_id, vehicle_value, tonnage, licensedtocarry, antitheft, risk, amount
    FROM VehiclePurchaseSnapshot
    WHERE purchase_id = p_purchase_id;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetList
-- Filterable, paginated. NULL filters are ignored — e.g. Support passes
-- all NULL to see everything, an Agent passes their own user_id.
-- p_payment_status filters on Purchases.payment_status (PENDING/PAID) -
-- separate from p_status, which is the policy's own lifecycle
-- (ACTIVE/EXPIRED/CANCELLED). Pass p_payment_status='PENDING' to get the
-- "awaiting payment confirmation" queue - every purchase whose payment
-- hasn't been confirmed SUCCESS yet, regardless of whether that's because
-- no Payment attempt was ever recorded, an STK push was never completed,
-- or the customer intends to pay via Paybill later. This is the same
-- payment_status column PUT /api/payments/{id}/status flips to PAID -
-- until a callback/background job resolves it that way (not built yet),
-- this queue is how staff find what still needs following up.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetList $$
CREATE PROCEDURE usp_Purchase_GetList (
    IN  p_client_id            BIGINT UNSIGNED,
    IN  p_purchased_by_user_id BIGINT UNSIGNED,
    IN  p_product_id           BIGINT UNSIGNED,
    IN  p_underwriter_id       BIGINT UNSIGNED,
    IN  p_status               VARCHAR(20),
    IN  p_payment_status       VARCHAR(20),
    IN  p_date_from            DATE,
    IN  p_date_to              DATE,
    IN  p_page_number          INT,
    IN  p_page_size            INT,
    OUT o_result_code          INT,
    OUT o_result_message       VARCHAR(500),
    OUT o_total_count          BIGINT
)
proc_label: BEGIN
    DECLARE v_offset INT;

    IF p_page_number IS NULL OR p_page_number < 1 THEN SET p_page_number = 1; END IF;
    IF p_page_size IS NULL OR p_page_size < 1 THEN SET p_page_size = 20; END IF;
    SET v_offset = (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO o_total_count
    FROM Purchases pu
    WHERE (p_client_id IS NULL OR pu.client_id = p_client_id)
      AND (p_purchased_by_user_id IS NULL OR pu.purchased_by_user_id = p_purchased_by_user_id)
      AND (p_product_id IS NULL OR pu.product_id = p_product_id)
      AND (p_underwriter_id IS NULL OR pu.underwriter_id = p_underwriter_id)
      AND (p_status IS NULL OR pu.status = p_status)
      AND (p_payment_status IS NULL OR pu.payment_status = p_payment_status)
      AND (p_date_from IS NULL OR pu.created_on >= p_date_from)
      AND (p_date_to IS NULL OR pu.created_on < DATE_ADD(p_date_to, INTERVAL 1 DAY));

    SELECT pu.purchase_id, pu.product_id, pr.code AS product_code, pu.client_id, c.full_name AS client_name,
           pu.purchased_by_user_id, pu.underwriter_id, u.name AS underwriter_name,
           pu.premium_amount, pu.policy_number, pu.payment_status, pu.status, pu.created_on
    FROM Purchases pu
    JOIN Products pr ON pr.product_id = pu.product_id
    JOIN Underwriters u ON u.underwriter_id = pu.underwriter_id
    JOIN Clients c ON c.client_id = pu.client_id
    WHERE (p_client_id IS NULL OR pu.client_id = p_client_id)
      AND (p_purchased_by_user_id IS NULL OR pu.purchased_by_user_id = p_purchased_by_user_id)
      AND (p_product_id IS NULL OR pu.product_id = p_product_id)
      AND (p_underwriter_id IS NULL OR pu.underwriter_id = p_underwriter_id)
      AND (p_status IS NULL OR pu.status = p_status)
      AND (p_payment_status IS NULL OR pu.payment_status = p_payment_status)
      AND (p_date_from IS NULL OR pu.created_on >= p_date_from)
      AND (p_date_to IS NULL OR pu.created_on < DATE_ADD(p_date_to, INTERVAL 1 DAY))
    ORDER BY pu.created_on DESC
    LIMIT p_page_size OFFSET v_offset;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_UpdateStatus
-- E.g. cancelling a policy, or a scheduled job marking EXPIRED once
-- end_date has passed.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_UpdateStatus $$
CREATE PROCEDURE usp_Purchase_UpdateStatus (
    IN  p_purchase_id    BIGINT UNSIGNED,
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

    IF p_purchase_id IS NULL OR p_status IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id and status are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('ACTIVE','EXPIRED','CANCELLED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be ACTIVE, EXPIRED or CANCELLED.';
        LEAVE proc_label;
    END IF;

    SELECT status INTO v_old_status FROM Purchases WHERE purchase_id = p_purchase_id;

    IF v_old_status IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Purchases SET status = p_status WHERE purchase_id = p_purchase_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'USER'), p_actor_id, 'STATUS_CHANGE', 'Purchases', p_purchase_id,
            JSON_OBJECT('status', v_old_status), JSON_OBJECT('status', p_status), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$


-- ---------------------------------------------------------------------
-- usp_Purchase_GetSummary
-- Single-row rollup for dashboard stat cards: how many policies are
-- ACTIVE/EXPIRED/CANCELLED, and how many are still waiting on payment
-- (PENDING/PAID/FAILED via Purchases.payment_status - the same column
-- usp_Purchase_GetList's p_payment_status filter reads). p_purchased_by_user_id
-- is optional: NULL gives the platform-wide totals (SuperAdmin/AgentAdmin/
-- SupportAgent dashboards); passed, it scopes everything to one agent's own
-- purchases (the Agent role's dashboard - "how many policies have I sold").
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetSummary $$
CREATE PROCEDURE usp_Purchase_GetSummary (
    IN  p_purchased_by_user_id BIGINT UNSIGNED,
    OUT o_result_code          INT,
    OUT o_result_message       VARCHAR(500)
)
BEGIN
    -- COALESCE(..., 0) matters here: SUM() over zero matching rows (e.g. a
    -- brand-new agent with no purchases yet) returns SQL NULL, not 0, since
    -- there's no GROUP BY to fall back on per-group zeros the way
    -- usp_QuoteRequest_GetSummary's LEFT JOIN does. Without this, the C#
    -- reader's Convert.ToInt64 would throw on a DBNull value.
    SELECT
        COALESCE(SUM(pu.status = 'ACTIVE'), 0)          AS active_count,
        COALESCE(SUM(pu.status = 'EXPIRED'), 0)         AS expired_count,
        COALESCE(SUM(pu.status = 'CANCELLED'), 0)       AS cancelled_count,
        COALESCE(SUM(pu.payment_status = 'PENDING'), 0) AS payment_pending_count,
        COALESCE(SUM(pu.payment_status = 'PAID'), 0)    AS payment_paid_count,
        COALESCE(SUM(pu.payment_status = 'FAILED'), 0)  AS payment_failed_count,
        COUNT(*)                                        AS total_count
    FROM Purchases pu
    WHERE (p_purchased_by_user_id IS NULL OR pu.purchased_by_user_id = p_purchased_by_user_id);

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetPeriodTotals
-- Single-row rollup for the dashboard's "Monthly Purchases"/"Daily
-- Purchases" widgets: how many policies were bought, and how much premium
-- they represent, today and so far this calendar month (today's own
-- activity is always included in the month's total too - not mutually
-- exclusive periods, same as any "today / month-to-date" pair of
-- headline numbers). Always platform-wide - no purchasedByUserId filter,
-- since these two widgets only ever appear on the back-office dashboard.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetPeriodTotals $$
CREATE PROCEDURE usp_Purchase_GetPeriodTotals (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT
        COALESCE(SUM(pu.created_on >= CURDATE()), 0) AS today_count,
        COALESCE(SUM(IF(pu.created_on >= CURDATE(), pu.premium_amount, 0)), 0) AS today_premium_total,
        COALESCE(SUM(pu.created_on >= DATE_FORMAT(CURDATE(), '%Y-%m-01')), 0) AS month_count,
        COALESCE(SUM(IF(pu.created_on >= DATE_FORMAT(CURDATE(), '%Y-%m-01'), pu.premium_amount, 0)), 0) AS month_premium_total
    FROM Purchases pu;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetByUnderwriter
-- Top 10 underwriters by premium written - the dashboard's "Top
-- Underwriters" chart (this platform's equivalent of a multi-underwriter
-- reference dashboard's "Top Selling Companies" - Amura brokers policies
-- across several underwriters the same way, this is that same ranking).
-- Fixed LIMIT 10, no IN params - always platform-wide, always "top N",
-- never scoped to one caller.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetByUnderwriter $$
CREATE PROCEDURE usp_Purchase_GetByUnderwriter (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT u.underwriter_id, u.name AS underwriter_name,
           COUNT(pu.purchase_id) AS purchase_count,
           COALESCE(SUM(pu.premium_amount), 0) AS premium_total
    FROM Purchases pu
    JOIN Underwriters u ON u.underwriter_id = pu.underwriter_id
    GROUP BY u.underwriter_id, u.name
    ORDER BY premium_total DESC
    LIMIT 10;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetByProduct
-- Every product's purchase count + premium total (not top-N - the
-- dashboard's "Sales per Product" table lists all of them with a % of
-- grand total, computed in the API/AdminPortal layer from these raw sums
-- rather than in SQL, so this proc stays a plain rollup). Products with
-- zero purchases are left out entirely (INNER JOIN) - unlike
-- usp_QuoteRequest_GetSummary's zero-filling LEFT JOIN, a product that has
-- never sold isn't interesting on a "sales" table the same way an empty
-- quote queue is.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetByProduct $$
CREATE PROCEDURE usp_Purchase_GetByProduct (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT pr.product_id, pr.code AS product_code, pr.name AS product_name,
           COUNT(pu.purchase_id) AS purchase_count,
           COALESCE(SUM(pu.premium_amount), 0) AS premium_total
    FROM Purchases pu
    JOIN Products pr ON pr.product_id = pu.product_id
    GROUP BY pr.product_id, pr.code, pr.name
    ORDER BY premium_total DESC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetMonthlyTrend
-- Exactly 6 rows, oldest to newest, one per calendar month including the
-- current one - a recursive CTE generates the 6 month buckets first and
-- LEFT JOINs purchases onto them, so a month with zero purchases still
-- comes back as a real zero-filled row instead of silently vanishing
-- (same reasoning as usp_QuoteRequest_GetSummary's LEFT JOIN from
-- Products - a trend chart with a gap in the x-axis is worse than one
-- showing a genuine zero).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetMonthlyTrend $$
CREATE PROCEDURE usp_Purchase_GetMonthlyTrend (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    WITH RECURSIVE months AS (
        SELECT DATE_FORMAT(CURDATE(), '%Y-%m-01') AS month_start, 0 AS n
        UNION ALL
        SELECT DATE_SUB(month_start, INTERVAL 1 MONTH), n + 1 FROM months WHERE n < 5
    )
    SELECT
        DATE_FORMAT(m.month_start, '%Y-%m') AS year_month,
        DATE_FORMAT(m.month_start, '%b %Y') AS month_label,
        COUNT(pu.purchase_id) AS purchase_count,
        COALESCE(SUM(pu.premium_amount), 0) AS premium_total
    FROM months m
    LEFT JOIN Purchases pu ON pu.created_on >= m.month_start
                           AND pu.created_on < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
    GROUP BY m.month_start
    ORDER BY m.month_start ASC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Purchase_GetTopAgents
-- Top 10 agents by policies sold (purchase count, not premium - matches
-- the dashboard label "Top 10 by policies sold"). INNER JOIN to Users/
-- Roles naturally excludes agents with zero purchases - nothing to rank
-- them against anyway. Only Agent-role purchases count here (an
-- AgentAdmin or SupportAgent can also execute a purchase on a client's
-- behalf via PurchasesController.Create, but this leaderboard is about
-- agents' own sales performance specifically, not every staff role).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Purchase_GetTopAgents $$
CREATE PROCEDURE usp_Purchase_GetTopAgents (
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SELECT u.user_id AS agent_user_id, u.full_name AS agent_name,
           COUNT(pu.purchase_id) AS purchase_count,
           COALESCE(SUM(pu.premium_amount), 0) AS premium_total
    FROM Purchases pu
    JOIN Users u ON u.user_id = pu.purchased_by_user_id
    JOIN Roles r ON r.role_id = u.role_id AND r.role_code = 'AG'
    WHERE u.isdeleted = 0
    GROUP BY u.user_id, u.full_name
    ORDER BY purchase_count DESC
    LIMIT 10;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- =====================================================================
-- PAYMENTS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_Payment_Create
-- Records a payment attempt as PENDING. For USSD/M-Pesa STK push, this
-- is called immediately when the push is initiated — the session ends
-- before the customer necessarily completes it, so completion is
-- confirmed later via usp_Payment_UpdateStatus from the payment webhook.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_Create $$
CREATE PROCEDURE usp_Payment_Create (
    IN  p_purchase_id          BIGINT UNSIGNED,
    IN  p_amount                DECIMAL(18,2),
    IN  p_method                  VARCHAR(20),
    IN  p_payer_phone               VARCHAR(20),
    IN  p_transaction_reference        VARCHAR(100),
    IN  p_actor_type                     VARCHAR(20),   -- USER / CLIENT / CHANNEL_SERVICE — who/what initiated payment
    IN  p_actor_id                         BIGINT UNSIGNED,
    OUT o_result_code                        INT,
    OUT o_result_message                       VARCHAR(500),
    OUT o_payment_id                             BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_purchase_id IS NULL OR p_amount IS NULL OR p_method IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'purchase_id, amount and method are required.';
        LEAVE proc_label;
    END IF;

    IF p_method NOT IN ('MPESA','CARD','BANK') THEN
        SET o_result_code = 1;
        SET o_result_message = 'method must be MPESA, CARD or BANK.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Purchases WHERE purchase_id = p_purchase_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Purchase not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Payments (purchase_id, amount, method, payer_phone, transaction_reference,
                           status, initiated_on)
    VALUES (p_purchase_id, p_amount, p_method, p_payer_phone, p_transaction_reference,
            'PENDING', NOW());

    SET o_payment_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CLIENT'), COALESCE(p_actor_id, p_purchase_id), 'CREATE', 'Payments', o_payment_id,
            NULL, JSON_OBJECT('purchase_id', p_purchase_id, 'amount', p_amount, 'method', p_method), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Payment_UpdateStatus
-- Called from the payment gateway webhook/callback. On SUCCESS, also
-- flips Purchases.payment_status to PAID.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_UpdateStatus $$
CREATE PROCEDURE usp_Payment_UpdateStatus (
    IN  p_payment_id            BIGINT UNSIGNED,
    IN  p_status                VARCHAR(20),
    IN  p_transaction_reference VARCHAR(100),
    IN  p_actor_type            VARCHAR(20),   -- typically CHANNEL_SERVICE (the payment gateway's service account)
    IN  p_actor_id              BIGINT UNSIGNED,
    OUT o_result_code           INT,
    OUT o_result_message        VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_purchase_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_payment_id IS NULL OR p_status IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'payment_id and status are required.';
        LEAVE proc_label;
    END IF;

    IF p_status NOT IN ('PENDING','SUCCESS','FAILED') THEN
        SET o_result_code = 1;
        SET o_result_message = 'status must be PENDING, SUCCESS or FAILED.';
        LEAVE proc_label;
    END IF;

    SELECT purchase_id INTO v_purchase_id FROM Payments WHERE payment_id = p_payment_id;

    IF v_purchase_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Payment not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Payments
    SET status = p_status,
        transaction_reference = COALESCE(p_transaction_reference, transaction_reference),
        completed_on = IF(p_status IN ('SUCCESS','FAILED'), NOW(), completed_on)
    WHERE payment_id = p_payment_id;

    IF p_status = 'SUCCESS' THEN
        UPDATE Purchases SET payment_status = 'PAID' WHERE purchase_id = v_purchase_id;
    ELSEIF p_status = 'FAILED' THEN
        UPDATE Purchases SET payment_status = 'FAILED' WHERE purchase_id = v_purchase_id;
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES (COALESCE(p_actor_type, 'CHANNEL_SERVICE'), COALESCE(p_actor_id, v_purchase_id), 'STATUS_CHANGE', 'Payments', p_payment_id,
            NULL, JSON_OBJECT('status', p_status), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Payment_GetByPurchase
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_GetByPurchase $$
CREATE PROCEDURE usp_Payment_GetByPurchase (
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

    SELECT payment_id, purchase_id, amount, method, payer_phone, transaction_reference,
           status, initiated_on, completed_on
    FROM Payments
    WHERE purchase_id = p_purchase_id
    ORDER BY initiated_on DESC;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Payment_GetSummary
-- Single-row rollup for dashboard stat cards: how many payment attempts
-- are PENDING/SUCCESS/FAILED, plus the total amount actually collected
-- (SUM of SUCCESS payments only - PENDING/FAILED never contributed real
-- money). p_purchased_by_user_id is optional, same scoping convention as
-- usp_Purchase_GetSummary - joins through Purchases since Payments itself
-- has no purchased-by column of its own.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Payment_GetSummary $$
CREATE PROCEDURE usp_Payment_GetSummary (
    IN  p_purchased_by_user_id BIGINT UNSIGNED,
    OUT o_result_code          INT,
    OUT o_result_message       VARCHAR(500)
)
BEGIN
    SELECT
        COALESCE(SUM(pm.status = 'PENDING'), 0)                    AS pending_count,
        COALESCE(SUM(pm.status = 'SUCCESS'), 0)                    AS success_count,
        COALESCE(SUM(pm.status = 'FAILED'), 0)                     AS failed_count,
        COUNT(*)                                                   AS total_count,
        COALESCE(SUM(IF(pm.status = 'SUCCESS', pm.amount, 0)), 0)  AS total_collected
    FROM Payments pm
    JOIN Purchases pu ON pu.purchase_id = pm.purchase_id
    WHERE (p_purchased_by_user_id IS NULL OR pu.purchased_by_user_id = p_purchased_by_user_id);

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
