-- =====================================================================
-- SCAPI-side M-Pesa configuration for the insurance platform
-- ---------------------------------------------------------------------
-- Target DB : the `scapi` database used by RAPIMVCASPCORE / RMPESAMANAGER
--             (their appsettings.json: database=scapi).
-- Short code: 4137235
--
-- WHY THIS EXISTS
-- The insurance API's M-Pesa calls do NOT talk to Daraja directly - they
-- go through SCAPI (interface "MPESA"). SCAPI's RMPESAMANAGER broker needs
-- three things in THIS database before an STK push can work:
--   1. parameter 'MPESA_DARAJA_API'        - Daraja base URL
--   2. interface 'MPESA' (active)          - RabbitMQ in/out queues
--   3. mpesa_business_short_codes '4137235' - Daraja creds + callback URL
--
-- TABLE NAMES ARE NOT GUESSES - they are the names SCAPI's own code
-- passes to the get_records stored procedure (see RMPESAMANAGER\
-- MPESAMaster.cs:126,137,176,182 and RAPIMVCASPCORE\Controllers\
-- CoreController.cs:214). Always PLURAL:
--     parameters                  (item_key / item_value)
--     interfaces                  (id / interface_name / interface_host /
--                                  active / request_queue / response_queue)
--     mpesa_business_short_codes  (MpesaConsumerKey / MpesaConsumerSecret /
--                                  MpesaPassKey / MpesaCallBackUrl / Encrypted)
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
-- So STEP 2 below - calling get_records exactly the way the app calls it
-- - is the decisive test.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1 - DISCOVER (read-only; run and read the output)
-- ---------------------------------------------------------------------
SHOW TABLES LIKE 'parameter%';
SHOW TABLES LIKE 'interface%';
SHOW TABLES LIKE 'mpesa_business_short%';

SHOW CREATE TABLE `parameters`;
SHOW CREATE TABLE `interfaces`;
SHOW CREATE TABLE `mpesa_business_short_codes`;


-- ---------------------------------------------------------------------
-- STEP 2 - PROBE (read-only; THE decisive test)
-- These are the exact calls the app makes. A zero-row result - or an
-- error - is the bug. Do not skip to STEP 3 without reading this.
-- ---------------------------------------------------------------------
CALL get_records('parameters', 'MPESA_DARAJA_API');
CALL get_records('parameters', 'SMTP_HOST');
CALL get_records('parameters', 'SMTP_PORT');
CALL get_records('parameters', 'SMTP_FROM_EMAIL');
CALL get_records('parameters', 'SMTP_PASSWORD');
CALL get_records('parameters', 'EMAIL_HEADER');
CALL get_records('mpesa_business_short_codes', '4137235');
CALL get_records('interfaces', 'MPESA');


-- ---------------------------------------------------------------------
-- STEP 3 - CONFIGURE
-- Only run the statements that STEP 2 showed as missing/empty.
-- ---------------------------------------------------------------------

-- 3a. Daraja API base URL.
--     Production = https://api.safaricom.co.ke
--     Sandbox    = https://sandbox.safaricom.co.ke
INSERT INTO `parameters` (item_key, item_value)
VALUES ('MPESA_DARAJA_API', 'https://api.safaricom.co.ke')
ON DUPLICATE KEY UPDATE item_value = VALUES(item_value);

-- 3b. The MPESA interface row. request_queue / response_queue MUST be the
--     exact RabbitMQ queues RMPESAMANAGER listens on. Copy them from a
--     working interface row - do not invent queue names.
--     (Read the existing rows first: SELECT * FROM `interfaces`;)
-- UPDATE `interfaces` SET active = 1 WHERE interface_name = 'MPESA';
-- INSERT INTO `interfaces`
--   (interface_name, interface_host, request_queue, response_queue, active)
-- VALUES
--   ('MPESA', '<host>', '<mpesa-request-queue>', '<mpesa-response-queue>', 1);

-- 3c. The short code row carrying the Daraja credentials.
--     The key column name (the one holding '4137235') comes from
--     SHOW CREATE TABLE `mpesa_business_short_codes` in STEP 1 - it is
--     NOT known here. Replace <short_code_column> with it.
--
--     MpesaCallBackUrl is where Daraja posts the STK result - it must
--     point at SCAPI's own handler, which then forwards the result to
--     the caller's callback_url (our /api/mpesa/callback/stk).
INSERT INTO `mpesa_business_short_codes`
  (<short_code_column>, MpesaConsumerKey, MpesaConsumerSecret,
   MpesaPassKey, MpesaCallBackUrl, Encrypted)
VALUES
  ('4137235',
   '<DARAJA CONSUMER KEY>',
   '<DARAJA CONSUMER SECRET>',
   '<DARAJA PASSKEY>',
   'https://scapi.riziki.app/api/Solid/MobileMoney/MpesaDarajaCallBack',
   NULL)
ON DUPLICATE KEY UPDATE
  MpesaConsumerKey    = VALUES(MpesaConsumerKey),
  MpesaConsumerSecret = VALUES(MpesaConsumerSecret),
  MpesaPassKey        = VALUES(MpesaPassKey),
  MpesaCallBackUrl    = VALUES(MpesaCallBackUrl);

-- 3d. SMTP parameters - the email OTP route reads these and crashes the
--     same way when they are missing.
INSERT INTO `parameters` (item_key, item_value) VALUES
  ('SMTP_HOST',       '<smtp host>'),
  ('SMTP_PORT',       '<smtp port>'),
  ('SMTP_FROM_EMAIL', '<from address>'),
  ('SMTP_PASSWORD',   '<smtp password>'),
  ('EMAIL_HEADER',    '<email header text>')
ON DUPLICATE KEY UPDATE item_value = VALUES(item_value);


-- ---------------------------------------------------------------------
-- STEP 4 - VERIFY (re-run STEP 2; every call must now return a row)
-- ---------------------------------------------------------------------
CALL get_records('parameters', 'MPESA_DARAJA_API');
CALL get_records('mpesa_business_short_codes', '4137235');
CALL get_records('interfaces', 'MPESA');

SELECT * FROM `parameters`              WHERE item_key = 'MPESA_DARAJA_API';
SELECT * FROM `interfaces`              WHERE interface_name = 'MPESA';
SELECT * FROM `mpesa_business_short_codes`;
