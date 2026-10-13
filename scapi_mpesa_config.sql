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
-- three rows in THIS database before an STK push or a C2B registration can
-- work:
--   1. parameter item MPESA_DARAJA_API     - Daraja base URL
--   2. interface 'MPESA' (active)          - RabbitMQ in/out queues
--   3. mpesa_business_shortcode '4137235'  - Daraja creds + callback URL
--
-- STEP 1 DISCOVERS the real table/column names in THIS database (the scapi
-- core schema is not stored in the Insurance repo). STEP 2 then configures
-- the rows. Do not skip STEP 1 - confirm the exact names first.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1 - DISCOVER (read-only; run and read the output)
-- ---------------------------------------------------------------------
SHOW TABLES LIKE '%interface%';
SHOW TABLES LIKE '%parameter%';
SHOW TABLES LIKE '%shortcode%';

SHOW CREATE TABLE `interface`;
SHOW CREATE TABLE `parameter`;
SHOW CREATE TABLE `mpesa_business_shortcode`;

SELECT * FROM `interface`;
SELECT * FROM `parameter` WHERE item_key IN ('MPESA_DARAJA_API') OR item_key LIKE '%MPESA%';
SELECT * FROM `mpesa_business_shortcode`;


-- ---------------------------------------------------------------------
-- STEP 2 - CONFIGURE (adjust table/column names to match STEP 1)
-- ---------------------------------------------------------------------

-- 2a. Daraja API base URL. Production = https://api.safaricom.co.ke
--     Sandbox    = https://sandbox.safaricom.co.ke
INSERT INTO `parameter` (item_key, item_value, comments)
VALUES ('MPESA_DARAJA_API', 'https://api.safaricom.co.ke', 'Daraja base URL used by RMPESAMANAGER');
-- If the row already exists, update it instead of inserting:
-- UPDATE `parameter` SET item_value = 'https://api.safaricom.co.ke'
--  WHERE item_key = 'MPESA_DARAJA_API';


-- 2b. The MPESA interface row. request_queue / response_queue MUST be the
--     exact RabbitMQ queues RMPESAMANAGER listens on. If an MPESA row
--     already exists, just make sure it is active:
UPDATE `interface` SET active = 1 WHERE interface_name = 'MPESA';

-- If no MPESA row exists, copy the shape of a working row and set the real
-- queue names (replace the <...> placeholders):
-- INSERT INTO `interface`
--   (interface_name, request_queue, response_queue, dll_path, assembly, active, approved)
-- VALUES
--   ('MPESA', '<mpesa-request-queue>', '<mpesa-response-queue>', '', '', 1, 1);


-- 2c. The short code row carrying the Daraja credentials.
--     Column name variants to expect (confirm via STEP 1):
--       business short code : mpesa_business_shortcode
--       consumer key        : mpesa_consumer_key
--       consumer secret     : mpesa_consumer_secret
--       pass key            : mpesa_pass_key
--       callback URL        : mpesa_call_back_url
--
--     mpesa_call_back_url is where Daraja posts the STK result - point it
--     at SCAPI's own handler, which then forwards the result to the
--     caller's callback_url (the insurance API's /api/mpesa/callback/stk):
INSERT INTO `mpesa_business_shortcode`
  (mpesa_business_shortcode, mpesa_consumer_key, mpesa_consumer_secret, mpesa_pass_key, mpesa_call_back_url, active)
VALUES
  ('4137235',
   '<DARAJA CONSUMER KEY>',
   '<DARAJA CONSUMER SECRET>',
   '<DARAJA PASSKEY>',
   'https://scapi.riziki.app/api/Solid/MobileMoney/MpesaDarajaCallBack',
   1);
-- If the row already exists, update it instead:
-- UPDATE `mpesa_business_shortcode`
--    SET mpesa_consumer_key    = '<DARAJA CONSUMER KEY>',
--        mpesa_consumer_secret = '<DARAJA CONSUMER SECRET>',
--        mpesa_pass_key        = '<DARAJA PASSKEY>',
--        mpesa_call_back_url   = 'https://scapi.riziki.app/api/Solid/MobileMoney/MpesaDarajaCallBack',
--        active                = 1
--  WHERE mpesa_business_shortcode = '4137235';


-- ---------------------------------------------------------------------
-- STEP 3 - VERIFY
-- ---------------------------------------------------------------------
SELECT * FROM `parameter`              WHERE item_key = 'MPESA_DARAJA_API';
SELECT * FROM `interface`              WHERE interface_name = 'MPESA';
SELECT * FROM `mpesa_business_shortcode` WHERE mpesa_business_shortcode = '4137235';
