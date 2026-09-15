-- =====================================================================
-- Insurance Platform — Remove DEV/TEST staff logins from production
-- ---------------------------------------------------------------------
-- The DEV seed accounts (id_no 90000001..90000004, password Test@1234,
-- bcrypt hashes in Insurance_API_Schema.sql) must never exist on a live
-- system. Run this in the production database.
--
-- THIS FILE = SAFE DEFAULT: the four accounts are hard-locked and can
-- never log in again (status INACTIVE, isdeleted=1, an unrecoverable
-- password hash), but the rows stay because in a shared environment they
-- can be referenced by other tables (purchases, commissions, etc.).
--
-- To fully DELETE them, first run the optional "HARD DELETE" block at the
-- bottom of this file (uncomment it; it removes the seed users' test
-- purchases/payments/commissions/rates, then the rows themselves).
--
-- Example:
--   mysql --default-character-set=utf8mb4 -u esbuser -p insurance_platform
--     < prod_seed_account_purge.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Reference report (what exists in production today)
-- ---------------------------------------------------------------------
SELECT u.user_id, u.id_no, u.full_name, u.status,
       COUNT(p.purchase_id) AS purchase_count
  FROM Users u
  LEFT JOIN Purchases p ON p.purchased_by_user_id = u.user_id
 WHERE u.id_no IN ('90000001','90000002','90000003','90000004')
 GROUP BY u.user_id, u.id_no, u.full_name, u.status;

SELECT uc.user_id, uc.id_no,
       (SELECT COUNT(*) FROM Purchases           p  WHERE p.purchased_by_user_id = uc.user_id) AS purchases,
       (SELECT COUNT(*) FROM Commissions         c  WHERE c.agent_user_id        = uc.user_id) AS commissions,
       (SELECT COUNT(*) FROM AgentCommissionRates r WHERE r.agent_user_id        = uc.user_id) AS commission_rates
  FROM Users uc
 WHERE uc.id_no IN ('90000001','90000002','90000003','90000004');

-- ---------------------------------------------------------------------
-- 1. Lock the accounts out for good (applies regardless of mode).
-- ---------------------------------------------------------------------
UPDATE Users
   SET status                = 'INACTIVE',
       isdeleted             = 1,
       failed_login_attempts = 255,
       locked_until          = '2038-01-01 00:00:00',
       password_hash         = CONCAT('$2b$11$', UCASE(SHA2(RAND(), 256))) -- unrecoverable replacement hash
 WHERE id_no IN ('90000001','90000002','90000003','90000004');

-- ---------------------------------------------------------------------
-- 2. HARD DELETE (OPTIONAL) - uncomment ONLY after confirming the
--    referenced purchases above are genuinely test data.
-- ---------------------------------------------------------------------
-- DELETE pm FROM Payments pm
--  JOIN Purchases pu ON pu.purchase_id = pm.purchase_id
-- WHERE pu.purchased_by_user_id IN (SELECT user_id FROM Users
--                                    WHERE id_no IN ('90000001','90000002','90000003','90000004'));
--
-- DELETE pu FROM Purchases pu
-- WHERE pu.purchased_by_user_id IN (SELECT user_id FROM Users
--                                    WHERE id_no IN ('90000001','90000002','90000003','90000004'));
--
-- DELETE FROM AgentCommissionRates
--  WHERE agent_user_id  IN (SELECT user_id FROM Users
--                             WHERE id_no IN ('90000001','90000002','90000003','90000004'))
--     OR set_by_user_id IN (SELECT user_id FROM Users
--                            WHERE id_no IN ('90000001','90000002','90000003','90000004'));
--
-- DELETE FROM Commissions
--  WHERE agent_user_id IN (SELECT user_id FROM Users
--                           WHERE id_no IN ('90000001','90000002','90000003','90000004'));
--
-- DELETE FROM Users WHERE id_no IN ('90000001','90000002','90000003','90000004');

-- ---------------------------------------------------------------------
-- 3. Verification: this report should be empty either way.
-- ---------------------------------------------------------------------
SELECT 'Remaining live seed accounts (must be empty):' AS note;
SELECT user_id, id_no, status, isdeleted
  FROM Users
 WHERE id_no IN ('90000001','90000002','90000003','90000004')
   AND (status = 'ACTIVE' OR isdeleted = 0);