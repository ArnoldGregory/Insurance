-- =====================================================================
-- Motor rates batch 3 — 2026 (the rate cards batch 2 left out)
-- ---------------------------------------------------------------------
-- Sources (underwriting files sent by the client, Oct 2026):
--   * HERITAGE NEW MOTOR PRIVATE TERMS (eff. 01/10/2026 new business)
--       -> Heritage (HERITAGE)   [scanned PDF, read page by page]
--   * FIDELITY-2026 Motor Underwriting Update (eff. 01/08/2026)
--       -> Fidelity Shield (FID) private comprehensive + new TPO minimums
--   * Mornach / Monarch Updated Motor Pricing 2025 -> Monarch (MONARCH)
--   * RATES 2025 — PIONEER                         -> Pioneer (PIONEER)
--   * DEFINITE ADJUSTED PSV RATES 2025 (DAC/PSV/0002/2025)
--       -> Definite PSV-MATATU TPO by seats: 1 Week / 2 Weeks / 1 Month / 1 Year
--
-- Also fixes usp_ComprehensiveRateBand_GetOptions (section 0):
--   * the band's MINIMUM PREMIUM was never applied (e.g. APA 600,000 x 7.25%
--     = 43,500 was quoted although APA's minimum is 50,000);
--   * PVT (0.25%, min 2,500) was added for EVERY underwriter, including
--     those whose rate already includes PVT (Definite, MUA, Fidelity...);
--   * effective_from / effective_to were ignored, so future-dated rate
--     cards (Heritage from 01/10/2026) could not be loaded ahead of time.
--   Result columns are unchanged, so the API/website need no change.
--
-- Choices that need the client's confirmation are marked "CONFIRM".
-- Idempotent: safe to re-run. Run after motor_rates_2026_batch2.sql.
-- =====================================================================
USE insurance_platform;


-- ---------------------------------------------------------------------
-- 0) Comprehensive compare: min premium, PVT-included underwriters,
--    effective dates.
--    PVT is added unless the underwriter's active 'PVT' benefit row says
--    is_included_in_base = 1 (no PVT row = previous behaviour: add it).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_ComprehensiveRateBand_GetOptions;

DELIMITER //
CREATE PROCEDURE usp_ComprehensiveRateBand_GetOptions(
    IN p_vehicle_value DECIMAL(18,2),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SET o_result_code = 0;
    SET o_result_message = 'Success';

    SELECT
        x.underwriter_id,
        x.underwriter_name,
        x.rate_percent,
        x.min_premium,
        x.value_min,
        x.value_max,
        x.base_premium,
        x.pvt_amount,
        ROUND(x.base_premium + x.pvt_amount, 2) AS total_premium
    FROM (
        SELECT
            u.underwriter_id,
            u.name AS underwriter_name,
            rb.rate_percent,
            rb.min_premium,
            rb.value_min,
            rb.value_max,
            ROUND(GREATEST(p_vehicle_value * rb.rate_percent / 100, rb.min_premium), 2) AS base_premium,
            CASE
                WHEN (SELECT MAX(cb.is_included_in_base)
                        FROM ComprehensiveBenefit cb
                       WHERE cb.underwriter_id = u.underwriter_id
                         AND cb.benefit_code = 'PVT'
                         AND cb.is_active = 1) = 1
                    THEN 0.00
                ELSE ROUND(GREATEST(p_vehicle_value * 0.0025, 2500), 2)
            END AS pvt_amount
        FROM ComprehensiveRateBand rb
        INNER JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
        WHERE rb.is_active = 1
          AND u.is_active = 1
          AND p_vehicle_value >= rb.value_min
          AND p_vehicle_value <= rb.value_max
          AND rb.effective_from <= CURDATE()
          AND (rb.effective_to IS NULL OR rb.effective_to >= CURDATE())
    ) x
    ORDER BY total_premium ASC;
END //
DELIMITER ;


-- ---------------------------------------------------------------------
-- 1) Bring back Heritage (batch 2 hid it: no readable rates then).
-- ---------------------------------------------------------------------
UPDATE Underwriters SET is_active = 1 WHERE code = 'HERITAGE';


-- ---------------------------------------------------------------------
-- 2) COMPREHENSIVE RATE BANDS (private motor)
--    These four underwriters' private bands are owned by this file:
--    deactivate whatever they have, then insert / re-activate the exact
--    bands below (never deletes, so admin history is kept).
--
--    Heritage: the card has Low / High / Rare-model tiers; the value-band
--    table has no risk tier, so the LOW-RISK rates are loaded. CONFIRM:
--    High-risk / rare models (listed on the card) must be referred.
--    Fidelity: "Motor Private Minimum Premiums - Kes. 42,500" on every band.
--    Pioneer: one 37,500 basic minimum for the private card.
--    Monarch: 27,500 minimum; the over-2.5M band is 3.00%.
-- ---------------------------------------------------------------------
UPDATE ComprehensiveRateBand rb
JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
   SET rb.is_active = 0
 WHERE u.code IN ('HERITAGE','FID','MONARCH','PIONEER');

INSERT INTO ComprehensiveRateBand
    (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from, effective_to, is_active)
SELECT uw.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, b.effective_from, NULL, 1
FROM Underwriters uw
JOIN (VALUES
        -- Heritage (low-risk tier, new business from 01/10/2026; min SI 500,000)
        ROW('HERITAGE',   500000,   1000000, 7.00,  50000, DATE('2026-10-01')),
        ROW('HERITAGE',  1000001,   2000000, 5.00,  70000, DATE('2026-10-01')),
        ROW('HERITAGE',  2000001,   3000000, 3.50, 100000, DATE('2026-10-01')),
        ROW('HERITAGE',  3000001,   5000000, 2.75, 105000, DATE('2026-10-01')),
        ROW('HERITAGE',  5000001, 999999999, 2.50, 137500, DATE('2026-10-01')),
        -- Fidelity Shield private (all-inclusive rate, from 01/08/2026)
        ROW('FID',             0,    999999, 6.50,  42500, DATE('2026-08-01')),
        ROW('FID',       1000000,   1499999, 5.25,  42500, DATE('2026-08-01')),
        ROW('FID',       1500000,   2499999, 4.25,  42500, DATE('2026-08-01')),
        ROW('FID',       2500000,   3499999, 3.50,  42500, DATE('2026-08-01')),
        ROW('FID',       3500000, 999999999, 3.00,  42500, DATE('2026-08-01')),
        -- Monarch ("Mornach") motor private 2025
        ROW('MONARCH',    500000,   1500000, 4.00,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   1500001,   2000000, 3.75,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   2000001,   2500000, 3.50,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   2500001, 999999999, 3.00,  27500, DATE('2025-01-01')),
        -- Pioneer private & double cabins 2025 (max age 15, min value 500,000)
        ROW('PIONEER',    500000,    999999, 6.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   1000000,   1499999, 5.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   1500000,   2499999, 4.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   2500000,   4999999, 3.25,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   5000000, 999999999, 3.00,  37500, DATE('2025-01-01'))
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium, effective_from)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveRateBand rb
     WHERE rb.underwriter_id = uw.underwriter_id
       AND rb.value_min = b.value_min
       AND rb.value_max = b.value_max
       AND rb.rate_percent = b.rate_percent
       AND rb.min_premium = b.min_premium
       AND rb.effective_from = b.effective_from
);

-- Re-activate the exact bands above (covers re-runs after the deactivate).
UPDATE ComprehensiveRateBand rb
JOIN Underwriters uw ON uw.underwriter_id = rb.underwriter_id
JOIN (VALUES
        ROW('HERITAGE',   500000,   1000000, 7.00,  50000, DATE('2026-10-01')),
        ROW('HERITAGE',  1000001,   2000000, 5.00,  70000, DATE('2026-10-01')),
        ROW('HERITAGE',  2000001,   3000000, 3.50, 100000, DATE('2026-10-01')),
        ROW('HERITAGE',  3000001,   5000000, 2.75, 105000, DATE('2026-10-01')),
        ROW('HERITAGE',  5000001, 999999999, 2.50, 137500, DATE('2026-10-01')),
        ROW('FID',             0,    999999, 6.50,  42500, DATE('2026-08-01')),
        ROW('FID',       1000000,   1499999, 5.25,  42500, DATE('2026-08-01')),
        ROW('FID',       1500000,   2499999, 4.25,  42500, DATE('2026-08-01')),
        ROW('FID',       2500000,   3499999, 3.50,  42500, DATE('2026-08-01')),
        ROW('FID',       3500000, 999999999, 3.00,  42500, DATE('2026-08-01')),
        ROW('MONARCH',    500000,   1500000, 4.00,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   1500001,   2000000, 3.75,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   2000001,   2500000, 3.50,  27500, DATE('2025-01-01')),
        ROW('MONARCH',   2500001, 999999999, 3.00,  27500, DATE('2025-01-01')),
        ROW('PIONEER',    500000,    999999, 6.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   1000000,   1499999, 5.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   1500000,   2499999, 4.00,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   2500000,   4999999, 3.25,  37500, DATE('2025-01-01')),
        ROW('PIONEER',   5000000, 999999999, 3.00,  37500, DATE('2025-01-01'))
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium, effective_from)
  ON b.uw_code = uw.code
 AND rb.value_min = b.value_min
 AND rb.value_max = b.value_max
 AND rb.rate_percent = b.rate_percent
 AND rb.min_premium = b.min_premium
 AND rb.effective_from = b.effective_from
   SET rb.is_active = 1;


-- ---------------------------------------------------------------------
-- 3) COMPREHENSIVE BENEFITS
--    Percentage add-ons are seeded at their documented MINIMUM (the
--    benefit table holds a flat price), same convention as batch 1/2.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price,
     is_included_in_base, description, display_order)
SELECT uw.underwriter_id, b.benefit_code, b.benefit_name, b.default_price,
       b.is_included_in_base, b.description, b.display_order
FROM Underwriters uw
JOIN (VALUES
        -- Heritage
        ROW('HERITAGE','PVT','Political Violence & Terrorism',2500,0,'0.25% of vehicle value, min 2,500',1),
        ROW('HERITAGE','EXCESS_PROTECTOR','Excess Protector',5000,0,'0.5% of value (up to 2M) min 5,000; 0.25% above 2M min 6,000',2),
        ROW('HERITAGE','WINDSREEN','Windscreen',0,1,'Free limit 50,000; 10% above',3),
        ROW('HERITAGE','RADIO','Radio / Entertainment',0,1,'Free limit 50,000; 10% above',4),
        ROW('HERITAGE','TOWING','Towing / Recovery',0,1,'Free limit 50,000',5),
        ROW('HERITAGE','MEDICAL','Medical Expenses',0,1,'Free limit 50,000',6),
        ROW('HERITAGE','COURTESY_CAR','Car Hire',3000,0,'Limit 30,000 at 3,000/day (10%, first 3 days excess)',7),
        -- Monarch
        ROW('MONARCH','EXCESS_PROTECTOR','Excess Protector',3000,0,'0.25% of SI, min 3,000',1),
        ROW('MONARCH','PVT','Political Violence & Terrorism',2500,0,'0.25% of SI, min 2,500',2),
        ROW('MONARCH','LOSS_OF_USE','Loss of Use',3000,0,'3,000 for a max limit of 30,000',3),
        ROW('MONARCH','WINDSREEN','Windscreen',0,1,'Free limit 30,000; 10% above',4),
        ROW('MONARCH','RADIO','Radio / Entertainment',0,1,'Free limit 30,000; 10% above',5),
        -- Pioneer (EP & PVT included from 1,000,000; charged below that)
        -- CONFIRM: the card includes EP & PVT in the rate from 1,000,000 up, but
        -- charges them below 1M. One flag per underwriter, so PVT is marked
        -- included (4 of 5 bands); the 500K-999,999 band's PVT (min 2,500) is
        -- therefore not added and the excess protector is offered as an add-on.
        ROW('PIONEER','EXCESS_PROTECTOR','Excess Protector',5000,0,'Below 1M: 0.25% min 5,000 (included from 1M)',1),
        ROW('PIONEER','PVT','Political Violence & Terrorism',0,1,'Included from 1M (below 1M: 0.25% min 2,500)',2),
        ROW('PIONEER','COURTESY_CAR','Courtesy Car',4500,0,'4,500 for 10 days / 30,000 (7,500 for 20 days / 60,000)',3)
     ) AS b(uw_code, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveBenefit cb
     WHERE cb.underwriter_id = uw.underwriter_id
       AND cb.benefit_code = b.benefit_code
);

-- Fidelity's benefits were seeded from its COMMERCIAL terms. The website's
-- comprehensive compare is private-car only, so align the two rows that
-- differ with the Aug-2026 private card (rate is "all inclusive", PVT and
-- excess protector 0.25% min 2,500). Only touches rows still holding the
-- batch-1 seeded values, so an admin's later edit is never overwritten.
UPDATE ComprehensiveBenefit cb
JOIN Underwriters u ON u.underwriter_id = cb.underwriter_id
   SET cb.default_price = 2500,
       cb.description = 'Private: 0.25% of vehicle value, min 2,500'
 WHERE u.code = 'FID' AND cb.benefit_code = 'EXCESS_PROTECTOR' AND cb.default_price = 5000;

-- (Fidelity PVT stays "included in base" - the private rate is all-inclusive.)


-- ---------------------------------------------------------------------
-- 4) COMPREHENSIVE LIABILITY LIMITS
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveLiabilityLimit
    (underwriter_id, limit_name, limit_value, display_order)
SELECT uw.underwriter_id, l.limit_name, l.limit_value, l.display_order
FROM Underwriters uw
JOIN (VALUES
        ROW('HERITAGE','Third Party Persons (per person)','3,000,000',1),
        ROW('HERITAGE','Third Party Persons (per event)','Unlimited',2),
        ROW('HERITAGE','Third Party Property','10,000,000',3),
        ROW('HERITAGE','Passenger Liability (per person / in all)','3,000,000 / 20,000,000',4),
        ROW('HERITAGE','Towing Charges','50,000',5),
        ROW('HERITAGE','Repair Authority','50,000',6),
        ROW('HERITAGE','Medical Expenses','50,000',7),
        ROW('HERITAGE','Radio Cassette','50,000',8),
        ROW('HERITAGE','Windscreen','50,000',9)
     ) AS l(uw_code, limit_name, limit_value, display_order)
  ON l.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveLiabilityLimit ll
     WHERE ll.underwriter_id = uw.underwriter_id
       AND ll.limit_name = l.limit_name
);


-- ---------------------------------------------------------------------
-- 5) TPO
--  5a) Fidelity (update effective 01/08/2026): private 15,000; commercial
--      "strict minimum of Kes 25,000 per vehicle"; tractors 10,000.
--      CONFIRM: prime mover + trailer quoted as 25,000 each (50,000 both).
--      Fidelity's TPO is owned by this file (it had none before).
--  5b) Definite PSV matatu by seats (DAC/PSV/0002/2025): 7 days, 14 days,
--      30 days and annual premiums per exact seat count (7 - 105 seats).
--      Batch 2 seeded no PSV-MATATU rows for Definite, so these are new.
--      Instalment plans (3/6/9/10) are not modelled - annual only.
-- ---------------------------------------------------------------------
DELETE t
FROM TpoPriceMapping t
JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
JOIN MotorVehicleClasses vc ON vc.vehicle_class_id = t.vehicle_class_id
WHERE u.code = 'FID'
   OR (u.code = 'DEFINITE' AND vc.name = 'PSV-MATATU');

INSERT INTO TpoPriceMapping
    (underwriter_id, vehicle_class_id, period_id, band_min, band_max,
     price, effective_from, effective_to, is_active, created_on)
SELECT u.underwriter_id, vc.vehicle_class_id, p.period_id, x.band_min, x.band_max,
       x.price, DATE('2026-08-01'), NULL, 1, NOW()
FROM (VALUES
        ROW('FID','PRIVATE','1 Year',NULL,NULL,15000),
        ROW('FID','MOTOR COMMERCIAL:OWN GOODS','1 Year',NULL,NULL,25000),
        ROW('FID','MOTOR COMMERCIAL:GENERAL','1 Year',NULL,NULL,25000),
        ROW('FID','MOTOR COMMERCIAL:Prime Mover','1 Year',NULL,NULL,25000),
        ROW('FID','MOTOR COMMERCIAL:Trailer','1 Year',NULL,NULL,25000),
        ROW('FID','MOTOR COMMERCIAL:TRACTOR','1 Year',NULL,NULL,10000)
     ) AS x(uw_code, class_name, period_name, band_min, band_max, price)
JOIN Underwriters u ON u.code = x.uw_code
JOIN MotorVehicleClasses vc ON vc.name = x.class_name
JOIN Periods p ON p.name = x.period_name AND p.is_active = 1;

-- Definite PSV matatu: one row per seat count (band_min = band_max = seats).
-- Columns: seats, 30 days, 14 days, 7 days, annual (premium less KES 40 stamp duty).
INSERT INTO TpoPriceMapping
    (underwriter_id, vehicle_class_id, period_id, band_min, band_max,
     price, effective_from, effective_to, is_active, created_on)
SELECT u.underwriter_id, vc.vehicle_class_id, p.period_id, s.seats, s.seats,
       CASE p.name
           WHEN '1 Month'  THEN s.d30
           WHEN '2 Weeks'  THEN s.d14
           WHEN '1 Week'   THEN s.d7
           WHEN '1 Year'   THEN s.annual
       END,
       DATE('2025-01-01'), NULL, 1, NOW()
FROM (VALUES
        ROW(7,6305,3786,2150,70025), ROW(8,6575,3963,2200,72904), ROW(9,6845,4142,2300,75873),
        ROW(10,7114,4324,2400,78755), ROW(11,7220,4315,2500,79822), ROW(12,7655,4593,2550,84602),
        ROW(13,7922,4775,2650,87483), ROW(14,7925,4750,2750,88357), ROW(15,8373,5045,2800,93332),
        ROW(16,8644,5225,2900,96215), ROW(17,8915,5403,3000,99185), ROW(18,9185,5493,3100,102062),
        ROW(19,9455,5675,3200,104943), ROW(20,9726,5856,3250,107915), ROW(21,9902,6034,3350,110793),
        ROW(22,10174,6122,3400,113676), ROW(23,10444,6305,3500,116642), ROW(24,10715,6482,3600,119523),
        ROW(25,10985,6665,3700,122493), ROW(26,11141,6704,3900,124329), ROW(27,11394,6802,4050,127166),
        ROW(28,11906,7142,4260,132944), ROW(29,11975,7220,4400,133826), ROW(30,12922,7738,4600,144503),
        ROW(31,13435,8080,4800,150283), ROW(32,13860,8333,4950,155552), ROW(33,13945,8370,5150,156132),
        ROW(34,14965,9012,5350,167623), ROW(35,15473,9268,5500,173403), ROW(36,17428,10461,6200,195335),
        ROW(37,17710,10690,6900,199292), ROW(38,18754,11253,7600,210977), ROW(39,19114,11484,8300,214902),
        ROW(40,19150,11575,9000,216323), ROW(41,19240,11520,9100,216259), ROW(42,19563,11715,9250,219521),
        ROW(43,19817,11908,9400,222785), ROW(44,20138,12099,9550,226115), ROW(45,20398,12225,9700,229377),
        ROW(46,20715,12415,9800,232643), ROW(47,20973,12611,9950,235907), ROW(48,21296,12737,10100,239172),
        ROW(49,21549,12930,10200,242436), ROW(50,21872,13123,10350,245761), ROW(51,22000,13190,10400,247300),
        ROW(52,22730,14700,10500,257000), ROW(53,23460,15000,10550,266500), ROW(54,24190,15200,10600,275300),
        ROW(55,24920,15400,10700,284100), ROW(56,25650,15700,10750,292800), ROW(57,26380,15900,10850,301560),
        ROW(58,27110,16150,10900,310400), ROW(59,27840,16400,11000,319080), ROW(60,28570,16620,11050,327840),
        ROW(61,29300,16850,11100,336600), ROW(62,30000,17000,11150,340000), ROW(63,31600,19200,11200,344900),
        ROW(64,31800,19300,11250,346900), ROW(65,31930,19450,11350,349900), ROW(66,31970,19450,11350,349900),
        ROW(67,32450,19650,11450,353900), ROW(68,32710,19750,11550,357900), ROW(69,32840,19900,11600,358400),
        ROW(70,33040,20000,11650,359900), ROW(71,33240,20100,11750,363900), ROW(72,33440,20200,11800,365900),
        ROW(73,33630,20350,11850,367900), ROW(74,33830,20450,11900,370400), ROW(75,34030,20550,12000,372900),
        ROW(76,34230,20650,12050,374400), ROW(77,34430,20750,12100,376900), ROW(78,34620,20900,12200,378400),
        ROW(79,34820,21000,12250,379900), ROW(80,35020,21100,12300,381400), ROW(81,35220,21200,12400,385400),
        ROW(82,35420,21350,12450,386900), ROW(83,35610,21460,12500,388400), ROW(84,35810,21550,12600,392400),
        ROW(85,36010,21650,12650,393900), ROW(86,36210,21800,12700,395400), ROW(87,36410,21900,12800,396900),
        ROW(88,36600,22000,12850,400900), ROW(89,36800,22100,12900,402400), ROW(90,37000,22250,12950,403900),
        ROW(91,37200,22360,13050,405400), ROW(92,37400,22450,13100,409400), ROW(93,37590,22550,13150,410900),
        ROW(94,37790,22700,13250,412400), ROW(95,37990,22800,13300,413900), ROW(96,38190,22900,13350,417900),
        ROW(97,38390,23000,13400,419400), ROW(98,38580,23100,13500,420900), ROW(99,38780,23250,13550,424900),
        ROW(100,38980,23350,13600,426400), ROW(101,39180,23500,13700,427900), ROW(102,39380,23550,13750,429400),
        ROW(103,39570,23700,13800,433400), ROW(104,39770,23800,13900,434900), ROW(105,39970,23900,13950,436900)
     ) AS s(seats, d30, d14, d7, annual)
JOIN Underwriters u ON u.code = 'DEFINITE'
JOIN MotorVehicleClasses vc ON vc.name = 'PSV-MATATU'
JOIN Periods p ON p.name IN ('1 Month','2 Weeks','1 Week','1 Year') AND p.is_active = 1;


-- ---------------------------------------------------------------------
-- 6) Verification
-- ---------------------------------------------------------------------
SELECT u.code, COUNT(*) AS active_bands, MIN(rb.effective_from) AS from_date
FROM ComprehensiveRateBand rb JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
WHERE rb.is_active = 1 AND u.code IN ('HERITAGE','FID','MONARCH','PIONEER')
GROUP BY u.code;

SELECT u.code, vc.name AS class_name, p.name AS period, COUNT(*) AS tpo_rows
FROM TpoPriceMapping t
JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
JOIN MotorVehicleClasses vc ON vc.vehicle_class_id = t.vehicle_class_id
JOIN Periods p ON p.period_id = t.period_id
WHERE t.is_active = 1 AND (u.code = 'FID' OR (u.code = 'DEFINITE' AND vc.name = 'PSV-MATATU'))
GROUP BY u.code, vc.name, p.name;

-- Spot check: APA 600,000 must now quote its 50,000 minimum (+ PVT).
CALL usp_ComprehensiveRateBand_GetOptions(600000, @rc, @rm);

-- =====================================================================
-- NOT SEEDED (needs data or a schema change):
--   * Heritage high-risk / rare-model tiers (no risk dimension on bands).
--   * Commercial / PSV COMPREHENSIVE (needs ComprehensiveRateFormula per
--     vehicle class) - Fidelity commercial, KOIL, Definite, MUA, Pioneer.
--   * Definite PSV instalment premiums (3/6/9/10 instalments).
--   * APA private TPO 12,000 (only sold alongside non-motor business).
-- =====================================================================
