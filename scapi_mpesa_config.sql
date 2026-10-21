-- =====================================================================
-- SCAPI-side M-Pesa configuration for the insurance platform
-- ---------------------------------------------------------------------
-- Target DB : the `scapi` database used by RAPIMVCASPCORE / RMPESAMANAGER
--             (their appsettings.json: server=164.92.97.131, database=scapi).
-- Short code: 4137235
--
-- WHY THIS EXISTS
-- The insurance API's M-Pesa calls do NOT talk to Daraja directly - they
-- go through SCAPI (interface "MPESA"). SCAPI's RMPESAMANAGER broker needs
-- three things in THIS database before an STK push can work:
--   1. parameter 'MPESA_DARAJA_API'        - Daraja base URL
--   2. interface 'MPESA' (active)          - RabbitMQ in/out queues
--   3. the mpesa business short code row   - Daraja creds + callback URL
--
-- NAME WARNING - READ THIS BEFORE RUNNING ANYTHING
-- SCAPI uses THREE different names for the same thing, and they are not
-- interchangeable:
--   * the get_records MODULE name (what the app passes to the SP):
--       'parameters', 'interfaces', 'mpesa_business_short_codes'
--   * the underlying TABLE names (singular for the two config tables):
--       'parameter', 'interfaces', 'mpesa_business_shortcode'
--   * the admin UI's own module name (no underscore before "codes"):
--       'mpesa_business_shortcodes'
-- Evidence: the module names are the literals in RMPESAMANAGER\MPESAMaster.cs
-- (126, 137, 176, 182) and RAPIMVCASPCORE\Controllers\CoreController.cs (214);
-- the table names come from the delete_records SP
-- ("DELETE FROM mpesa_business_shortcode WHERE id = recordid") and from the
-- admin UI's own data source ("data": "mpesa_business_shortcode").
-- So STEP 1 below DISCOVERS the table names instead of assuming them -
-- do not skip it.
--
-- THE 99 ERROR EXPLAINED
-- SCAPI's get_records helper CATCHES its own exceptions and returns an
-- EMPTY table, so a missing table or a missing row never surfaces as an
-- error - it surfaces as `.Rows[0]` throwing "Index was out of range"
-- inside RMPESAMANAGER, which kills the worker, which returns an empty
-- RPC reply, which makes CoreController's JToken.Parse throw, which
-- CoreController reports to us as:
--     {"error_code":"99","error_desc":"An unexpected error occurred. Please retry."}
-- The same empty-row crash in REMAILSERVICE (SMTP_HOST etc.) is why the
-- email OTP route fails with the identical 99.
--
-- SCOPE NOTE - measured on the live gateway on 2026-10-21
--     TOKEN  -> 00  (works; uses validate_api_consumer, not get_records)
--     SMS, EMAIL, MPESA (every short code) -> 99
-- so this is NOT specific to our short code and NOT specific to M-Pesa:
-- every SCAPI module that reads its settings through get_records is down.
-- STEP 2b below (SHOW CREATE PROCEDURE get_records) is the decisive test.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1 - DISCOVER TABLE NAMES (read-only; run and read the output)
-- ---------------------------------------------------------------------
SHOW TABLES LIKE '%shortcode%';
SHOW TABLES LIKE '%short_code%';
SHOW TABLES LIKE 'parameter%';
SHOW TABLES LIKE 'interface%';
SHOW TABLES LIKE 'mpesa%';
SHOW TABLES LIKE 'sms%';
SHOW TABLES LIKE 'email%';

-- Copy the real table names from the output above into STEP 2/3 below.
-- Expected (verify, don't assume):
--   short code table : mpesa_business_shortcode
--   parameters table : parameter
--   interface table  : interfaces


-- ---------------------------------------------------------------------
-- STEP 2 - PROBE (read-only; THE decisive test)
-- These are the exact calls the app makes. A zero-row result - or an
-- error - is the bug. Do not skip to STEP 3 without reading this.
-- ---------------------------------------------------------------------
-- 2a. the settings lookups
CALL get_records('parameters', 'MPESA_DARAJA_API');
CALL get_records('parameters', 'SMTP_HOST');
CALL get_records('parameters', 'SMTP_PORT');
CALL get_records('parameters', 'SMTP_FROM_EMAIL');
CALL get_records('parameters', 'SMTP_PASSWORD');
CALL get_records('parameters', 'EMAIL_HEADER');
-- 2b. the routing + credential lookups
CALL get_records('interfaces', 'MPESA');
CALL get_records('mpesa_business_short_codes', '4137235');

-- 2c. THE DEFINITIVE CHECK on the stored procedure itself.
-- get_records is a big IF/ELSEIF on the module name. If the branch for
-- 'mpesa_business_short_codes' (or 'interfaces' / 'sms' / 'email') is
-- missing from the installed procedure, EVERY module that needs it dies
-- with the same 99 - which is exactly what the live gateway is doing
-- today for SMS, EMAIL and MPESA alike. Read the output and look for:
--     ELSEIF module = 'mpesa_business_short_codes' THEN
--     ELSEIF module = 'interfaces' THEN
SHOW CREATE PROCEDURE `get_records`;


-- ---------------------------------------------------------------------
-- STEP 3 - HARVEST THE DARAJA CREDENTIALS (read-only)
-- This is what unblocks the direct-to-Daraja transport in the insurance
-- API, which does not need SCAPI to work at all: the insurance API can
-- call Daraja itself once it has the consumer key, consumer secret and
-- pass key for the short code.
-- Replace <short_code_table> with the name STEP 1 found.
-- ---------------------------------------------------------------------
SELECT * FROM `mpesa_business_shortcode`;

-- The base URL the short code is meant to talk to (production vs sandbox).
SELECT item_key, item_value FROM `parameter`
WHERE item_key IN ('MPESA_DARAJA_API', 'SCAPI_URL', 'SCAPI_USER',
                   'SCAPI_GATEWAY_PASSWORD', 'business_short_code');


-- ---------------------------------------------------------------------
-- STEP 4 - WHEN DID THE MPESA WORKER LAST WORK?
-- `mpesa_stk_push` is written by RMPESAMANAGER when a push is accepted,
-- and `request_log` is written by the SCAPI API for every request.
-- An empty mpesa_stk_push with request_log rows that all say 99 confirms
-- the worker is alive but failing on its own lookups.
-- ---------------------------------------------------------------------
SELECT * FROM `mpesa_stk_push` ORDER BY id DESC LIMIT 10;
SELECT * FROM `request_log`  ORDER BY id DESC LIMIT 20;


-- ---------------------------------------------------------------------
-- STEP 5 - CONFIGURE (only if STEP 2 showed something missing/empty)
-- ---------------------------------------------------------------------

-- 5a. Daraja API base URL.
--     Production = https://api.safaricom.co.ke
--     Sandbox    = https://sandbox.safaricom.co.ke
INSERT INTO `parameter` (item_key, item_value)
VALUES ('MPESA_DARAJA_API', 'https://api.safaricom.co.ke')
ON DUPLICATE KEY UPDATE item_value = VALUES(item_value);

-- 5b. The MPESA interface row. request_queue / response_queue MUST be the
--     exact RabbitMQ queues RMPESAMANAGER listens on. Copy them from a
--     working interface row - do not invent queue names.
--     (Read the existing rows first: SELECT * FROM `interfaces`;)
-- UPDATE `interfaces` SET active = 1 WHERE interface_name = 'MPESA';
-- INSERT INTO `interfaces`
--   (interface_name, interface_host, request_queue, response_queue, active)
-- VALUES
--   ('MPESA', '<host>', '<mpesa-request-queue>', '<mpesa-response-queue>', 1);

-- 5c. The short code row carrying the Daraja credentials.
--     The key column name (the one holding '4137235') comes from
--     SHOW CREATE TABLE - it is NOT known here. Replace
--     <short_code_column> with it. Only fill this in if the row is
--     genuinely missing; if the row EXISTS, do not overwrite working
--     credentials - the 99 is then caused by the get_records procedure
--     (STEP 2c) or by the RabbitMQ worker, not by the data.
--
--     MpesaCallBackUrl is where Daraja posts the STK result - it must
--     point at SCAPI's own handler, which then forwards the result to
--     the caller's callback_url (our /api/mpesa/callback/stk).
-- INSERT INTO `mpesa_business_shortcode`
--   (<short_code_column>, MpesaConsumerKey, MpesaConsumerSecret,
--    MpesaPassKey, MpesaCallBackUrl, Encrypted)
-- VALUES
--   ('4137235',
--    '<DARAJA CONSUMER KEY>',
--    '<DARAJA CONSUMER SECRET>',
--    '<DARAJA PASSKEY>',
--    'https://scapi.riziki.app/api/Solid/MobileMoney/MpesaDarajaCallBack',
--    NULL)
-- ON DUPLICATE KEY UPDATE
--   MpesaConsumerKey    = VALUES(MpesaConsumerKey),
--   MpesaConsumerSecret = VALUES(MpesaConsumerSecret),
--   MpesaPassKey        = VALUES(MpesaPassKey),
--   MpesaCallBackUrl    = VALUES(MpesaCallBackUrl);

-- 5d. SMTP parameters - the email OTP route reads these and crashes the
--     same way when they are missing.
INSERT INTO `parameter` (item_key, item_value) VALUES
  ('SMTP_HOST',       '<smtp host>'),
  ('SMTP_PORT',       '<smtp port>'),
  ('SMTP_FROM_EMAIL', '<from address>'),
  ('SMTP_PASSWORD',   '<smtp password>'),
  ('EMAIL_HEADER',    '<email header text>')
ON DUPLICATE KEY UPDATE item_value = VALUES(item_value);


-- ---------------------------------------------------------------------
-- STEP 6 - VERIFY (re-run STEP 2; every call must now return a row)
-- ---------------------------------------------------------------------
CALL get_records('parameters', 'MPESA_DARAJA_API');
CALL get_records('mpesa_business_short_codes', '4137235');
CALL get_records('interfaces', 'MPESA');

SELECT * FROM `parameter`             WHERE item_key = 'MPESA_DARAJA_API';
SELECT * FROM `interfaces`            WHERE interface_name = 'MPESA';
SELECT * FROM `mpesa_business_shortcode`;
