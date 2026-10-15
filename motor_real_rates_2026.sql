-- =====================================================================
-- Real motor underwriter rates — 2026
--   * Definite Assurance   Ref DAC/MOTOR/0001/2024  (+ DAC/PSV/0002/2025)
--   * Fidelity Shield      Ref FID/COMM/01/2026/UW   (21.01.2026)
--   * APA Insurance        Revised Motor Rates 2026  (new biz 12/01/2026)
-- =====================================================================
-- Where these land, and why:
--   * Comprehensive quote on the website is VALUE-BAND only (the customer
--     enters just a vehicle value) ->  ComprehensiveRateBand
--                                        ComprehensiveBenefit
--                                        ComprehensiveLiabilityLimit
--   * TPO is class + capacity/tonnage aware -> TpoPriceMapping
--   * Class-specific COMPREHENSIVE rates (the bulk of the commercial
--     documents) cannot be represented by the value-band table today;
--     they belong in ComprehensiveRateFormula (class-aware) and are
--     flagged as a follow-up at the bottom of this file.
--
-- Idempotent: every insert is guarded (JOIN / NOT EXISTS / ON DUPLICATE),
-- so this can be re-run safely and never wipes admin-edited rows.
-- =====================================================================
USE insurance_platform;

-- ---------------------------------------------------------------------
-- 1) UNDERWRITERS
--    Definite already exists (kept, never duplicated); Fidelity and APA
--    are new. Match on name so an existing row keeps its own code.
-- ---------------------------------------------------------------------
INSERT INTO Underwriters (name, code, is_active, created_on)
SELECT v.name, v.code, 1, NOW()
FROM (VALUES
        ROW('Definite Assurance', 'DEFINITE'),
        ROW('Fidelity Shield Insurance Company Limited', 'FID'),
        ROW('APA Insurance Limited', 'APA')
     ) AS v(name, code)
WHERE NOT EXISTS (SELECT 1 FROM Underwriters u WHERE u.name = v.name);


-- ---------------------------------------------------------------------
-- 2) COMPREHENSIVE RATE BANDS (private car, value bands)
--    Matches usp_ComprehensiveRateBand_GetOptions (value in / total out).
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveRateBand
    (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from)
SELECT uw.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, CURDATE()
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance - private (individual)
        ROW('DEFINITE',      500000,  1000000, 4.50, 30000),
        ROW('DEFINITE',     1000001,  2000000, 3.50, 30000),
        ROW('DEFINITE',     2000001, 999999999, 3.00, 30000),
        -- APA Insurance - private car
        ROW('APA',           600000,  1000000, 7.25, 50000),
        ROW('APA',          1000001,  1500000, 6.00, 50000),
        ROW('APA',          1500001,  2500000, 5.50, 50000),
        ROW('APA',          2500001,  5000000, 4.25, 50000),
        ROW('APA',          5000001, 10000000, 3.00, 50000),
        ROW('APA',         10000001, 999999999, 3.00, 50000)
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveRateBand rb
     WHERE rb.underwriter_id = uw.underwriter_id
       AND rb.value_min = b.value_min
       AND rb.value_max = b.value_max
);


-- ---------------------------------------------------------------------
-- 3) COMPREHENSIVE BENEFITS
--    Flat-price lines only. Percentage-based extras (excess protector,
--    PVT) are seeded at their DOCUMENTED MINIMUM as the add-on price.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price,
     is_included_in_base, description, display_order)
SELECT uw.underwriter_id, b.benefit_code, b.benefit_name, b.default_price,
       b.is_included_in_base, b.description, b.display_order
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance
        ROW('DEFINITE','EXCESS_PROTECTOR','Excess Protector',3000,0,'Own-damage excess waiver (0.25% of SI, min 3,000)',1),
        ROW('DEFINITE','PVT','Political Violence & Terrorism',0,1,'Included in base premium',2),
        ROW('DEFINITE','WINDSREEN','Windscreen',0,1,'Free windscreen cover',3),
        ROW('DEFINITE','TOWING','Towing / Recovery',0,1,'Free towing & recovery',4),
        ROW('DEFINITE','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        -- Fidelity Shield (commercial)
        ROW('FID','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.5% of SI, min 5,000)',1),
        ROW('FID','PVT','Political Violence & Terrorism',0,1,'Included in base premium',2),
        ROW('FID','WINDSREEN','Windscreen',0,1,'Free windscreen cover',3),
        ROW('FID','TOWING','Towing / Recovery',0,1,'Free towing / recovery',4),
        ROW('FID','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        ROW('FID','RADIO','Radio / CD Player',0,1,'Free radio / CD player cover',6),
        -- APA Insurance
        ROW('APA','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.25% of SI, min 5,000)',1),
        ROW('APA','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500 private / 5,000 commercial)',2),
        ROW('APA','WINDSREEN','Windscreen',0,1,'Free windscreen cover (50,000 / 100,000 limit)',3),
        ROW('APA','TOWING','Towing / Recovery',0,1,'Free towing cover',4),
        ROW('APA','MEDICAL','Emergency Medical Expenses',0,1,'Free emergency medical cover',5),
        ROW('APA','RADIO','Infotainment / Stereo Unit',0,1,'Free infotainment cover',6)
     ) AS b(uw_code, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveBenefit cb
     WHERE cb.underwriter_id = uw.underwriter_id
       AND cb.benefit_code = b.benefit_code
);


-- ---------------------------------------------------------------------
-- 4) COMPREHENSIVE LIABILITY LIMITS
--    ComprehensiveLiabilityLimit is per-underwriter (no class dimension),
--    so one representative commercial set is seeded per underwriter.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveLiabilityLimit
    (underwriter_id, limit_name, limit_value, display_order)
SELECT uw.underwriter_id, l.limit_name, l.limit_value, l.display_order
FROM Underwriters uw
JOIN (VALUES
        -- Definite Assurance (standard commercial)
        ROW('DEFINITE','Third Party Property Damage','10,000,000',1),
        ROW('DEFINITE','Third Party Bodily Injury (per person)','3,000,000',2),
        ROW('DEFINITE','Third Party Bodily Injury (per event)','100,000,000',3),
        ROW('DEFINITE','Passenger Legal Liability (per person)','3,000,000',4),
        ROW('DEFINITE','Passenger Legal Liability (per event)','20,000,000',5),
        -- Fidelity Shield (commercial, representative set)
        ROW('FID','Third Party Property Damage','10,000,000',1),
        ROW('FID','Third Party Bodily Injury (per person)','3,000,000',2),
        ROW('FID','Third Party Bodily Injury (per event)','100,000,000',3),
        ROW('FID','Passenger Legal Liability (per person)','3,000,000',4),
        ROW('FID','Passenger Legal Liability (per event)','20,000,000',5),
        ROW('FID','Authorized Repair (free limit)','100,000',6),
        ROW('FID','Medical Expenses (free limit)','50,000',7),
        ROW('FID','Towing / Recovery','100,000',8),
        ROW('FID','Windscreen (free limit)','50,000',9),
        -- APA Insurance
        ROW('APA','Third Party Property Damage (free limit)','20,000,000',1),
        ROW('APA','Third Party Bodily Injury / PLL (per person)','3,000,000',2),
        ROW('APA','Third Party Bodily Injury / PLL (per event)','20,000,000',3),
        ROW('APA','Authorized Repair','50,000',4),
        ROW('APA','Emergency Medical Expenses','50,000',5),
        ROW('APA','Towing / Recovery','50,000',6),
        ROW('APA','Windscreen (0.6M - 2.5M / >2.5M)','50,000 / 100,000',7),
        ROW('APA','Infotainment / Stereo','50,000 / 100,000',8)
     ) AS l(uw_code, limit_name, limit_value, display_order)
  ON l.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveLiabilityLimit ll
     WHERE ll.underwriter_id = uw.underwriter_id
       AND ll.limit_name = l.limit_name
);


-- ---------------------------------------------------------------------
-- 5) OPTIONAL — retire the placeholder comprehensive underwriters so the
--    website compare shows only the real partners above.
--    Review before enabling; this only flips is_active, it does not delete.
-- ---------------------------------------------------------------------
-- UPDATE Underwriters
--    SET is_active = 0
--  WHERE code IN ('MONARCH','MUA','HERITAGE','PACIS','OLDMUTUAL','KENINDIA','KENYA_ORIENT');


-- =====================================================================
-- FOLLOW-UP (NOT in this file — needs confirmation):
--   * Commercial / PSV COMPREHENSIVE rates are class-specific and do not
--     fit the value-band table. They go in ComprehensiveRateFormula
--     (underwriter_id, vehicle_class_id, base_rate_percent, min_premium).
--   * TPO rates per class -> TpoPriceMapping (vehicle_class_id + period;
--     carry_capacity for PSV, tonnage for commercial).
--   * Fidelity Shield publishes NO private-car rates, so it has no value
--     bands here (commercial-only insurer).
-- =====================================================================
