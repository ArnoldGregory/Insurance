-- =====================================================================
-- Motor rates batch 2 — 2026 (docs-backed underwriters)
-- ---------------------------------------------------------------------
-- Sources (underwriting files, Oct 2026):
--   * KOIL RATES MOTOR 2024               -> Kenya Orient (KENYA_ORIENT)
--   * OLD MUTUAL MOTOR PRIVATE RATES       -> Old Mutual (OLDMUTUAL)
--   * MUA MOTOR VEHICLE TERMS — MAY 2025   -> MUA (MUA)
--   * Mornach / Monarch Motor Pricing 2025 -> Monarch (MONARCH)
--   * DEFINITE ASSURANCE APPROVED RATES    -> Definite (DEFINITE)
--   * RATES 2025 — PIONEER                  -> Pioneer (new: PIONEER)
--
-- Scope:
--   * ComprehensiveRateBand (private motor, value bands) — the only shape
--     the website's comprehensive compare consumes today.
--   * TpoPriceMapping — now BANDED (see tpo_banded_pricing_migration.sql):
--       band_min/band_max in the class's rating unit (seats for PSV, tonnes
--       for Commercial); NULL/NULL = flat-rate class (Private, Motorcycle).
--     Only periods a document actually publishes are seeded — insurers that
--     state "no short-term TPO" get an annual row only (no invented short
--     rates).
--
-- Deliberately NOT seeded (needs your call — see notes at the bottom):
--   * image-only PDFs: Heritage, APA 2026 update, Fidelity private update.
--   * ambiguous tables: Monarch/Pioneer comprehensive private rates.
--   * Commercial/PSV COMPREHENSIVE (needs the class-aware formula path).
--
-- Idempotent: rate-band/benefit/limit guarded by NOT EXISTS; TPO for the
-- underwriters reseeded here is cleared then re-inserted (same final state
-- on every run). Safe to re-run.
-- =====================================================================
USE insurance_platform;

-- ---------------------------------------------------------------------
-- 1) New underwriter: Pioneer
-- ---------------------------------------------------------------------
INSERT INTO Underwriters (name, code, is_active, created_on)
SELECT 'Pioneer Insurance', 'PIONEER', 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM Underwriters WHERE code = 'PIONEER');


-- ---------------------------------------------------------------------
-- 2) COMPREHENSIVE RATE BANDS (private motor)
--    Each doc's private-motor value bands, verbatim.
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveRateBand
    (underwriter_id, value_min, value_max, rate_percent, min_premium, effective_from)
SELECT uw.underwriter_id, b.value_min, b.value_max, b.rate_percent, b.min_premium, CURDATE()
FROM Underwriters uw
JOIN (VALUES
        -- Kenya Orient (KOIL): min premium 35,000, max age 15
        ROW('KENYA_ORIENT',   500000,  1000000, 6.00, 35000),
        ROW('KENYA_ORIENT',  1000001,  2000000, 4.00, 35000),
        ROW('KENYA_ORIENT',  2000001,  3000000, 3.25, 35000),
        ROW('KENYA_ORIENT',  3000001, 999999999, 3.00, 35000),
        -- Old Mutual: min premium applies to first two bands only
        ROW('OLDMUTUAL',      500000,  1000000, 6.00, 37500),
        ROW('OLDMUTUAL',     1000001,  1500000, 5.00, 60000),
        ROW('OLDMUTUAL',     1500001,  2500000, 4.00,     0),
        ROW('OLDMUTUAL',     2500001,  2999999, 3.50,     0),
        ROW('OLDMUTUAL',     3000000,  4999999, 3.25,     0),
        ROW('OLDMUTUAL',     5000000, 999999999, 3.00,     0),
        -- MUA: min SI 500,000; excl. excess protector & PVT (included in rate)
        ROW('MUA',            500000,  2000000, 5.00, 45000),
        ROW('MUA',           2000001,  4000000, 3.50, 45000),
        ROW('MUA',           4000001, 999999999, 3.00, 45000)
     ) AS b(uw_code, value_min, value_max, rate_percent, min_premium)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveRateBand rb
     WHERE rb.underwriter_id = uw.underwriter_id
       AND rb.value_min = b.value_min
       AND rb.value_max = b.value_max
);


-- ---------------------------------------------------------------------
-- 3) COMPREHENSIVE BENEFITS (flat price = documented minimum; % extras)
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveBenefit
    (underwriter_id, benefit_code, benefit_name, default_price,
     is_included_in_base, description, display_order)
SELECT uw.underwriter_id, b.benefit_code, b.benefit_name, b.default_price,
       b.is_included_in_base, b.description, b.display_order
FROM Underwriters uw
JOIN (VALUES
        ROW('KENYA_ORIENT','EXCESS_PROTECTOR','Excess Protector',5000,0,'Own-damage excess protector (0.25% of SI, min 5,000)',1),
        ROW('KENYA_ORIENT','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500)',2),
        ROW('KENYA_ORIENT','RESCUE','Garicorp Rescue Services',4500,0,'Rescue / roadside (4,500)',3),
        ROW('OLDMUTUAL','EXCESS_PROTECTOR','Excess Protector',2500,0,'Own-damage excess protector (0.25% of SI, min 2,500)',1),
        ROW('OLDMUTUAL','PVT','Political Violence & Terrorism',2500,0,'PVT (0.25% of SI, min 2,500)',2),
        ROW('OLDMUTUAL','COURTESY_CAR','Courtesy Car',3000,0,'Courtesy car, 10 days, max 30,000',3),
        ROW('MUA','EXCESS_PROTECTOR','Excess Protector',0,1,'Included in base rate',1),
        ROW('MUA','PVT','Political Violence & Terrorism',0,1,'Included in base rate',2),
        ROW('MUA','TOWING','Towing / Recovery',0,1,'Free towing within Kenya',3),
        ROW('MUA','WINDSREEN','Windscreen',0,1,'Free limit 50,000 (SI <=2M) / 100,000 (SI >2M)',4)
     ) AS b(uw_code, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order)
  ON b.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveBenefit cb
     WHERE cb.underwriter_id = uw.underwriter_id
       AND cb.benefit_code = b.benefit_code
);


-- ---------------------------------------------------------------------
-- 4) COMPREHENSIVE LIABILITY LIMITS (where the doc publishes them)
-- ---------------------------------------------------------------------
INSERT INTO ComprehensiveLiabilityLimit
    (underwriter_id, limit_name, limit_value, display_order)
SELECT uw.underwriter_id, l.limit_name, l.limit_value, l.display_order
FROM Underwriters uw
JOIN (VALUES
        ROW('OLDMUTUAL','Third Party Persons (per person)','10,000,000',1),
        ROW('OLDMUTUAL','Third Party Persons (per period)','100,000,000',2),
        ROW('OLDMUTUAL','Third Party Property Damage','30,000,000',3),
        ROW('OLDMUTUAL','Passenger Liability (per person)','4,000,000',4),
        ROW('OLDMUTUAL','Passenger Liability (per event)','20,000,000',5),
        ROW('OLDMUTUAL','Towing & Recovery','100,000',6),
        ROW('OLDMUTUAL','Repair Authority','100,000',7),
        ROW('OLDMUTUAL','Medical Expenses','100,000',8),
        ROW('OLDMUTUAL','Entertainment Systems','100,000',9),
        ROW('OLDMUTUAL','Windscreen / Window Glass','100,000',10)
     ) AS l(uw_code, limit_name, limit_value, display_order)
  ON l.uw_code = uw.code
WHERE NOT EXISTS (
    SELECT 1 FROM ComprehensiveLiabilityLimit ll
     WHERE ll.underwriter_id = uw.underwriter_id
       AND ll.limit_name = l.limit_name
);


-- ---------------------------------------------------------------------
-- 5) TPO — clear the underwriters we are reseeding, then insert real bands.
--    (Their previous rows are placeholder values, not underwriter data.)
-- ---------------------------------------------------------------------
UPDATE TpoPriceMapping t
JOIN Underwriters u ON u.underwriter_id = t.underwriter_id
SET t.is_active = 0, t.effective_to = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
WHERE u.code IN ('MONARCH','MUA','KENYA_ORIENT','OLDMUTUAL','DEFINITE','PIONEER') AND t.is_active = 1;

INSERT INTO TpoPriceMapping
    (underwriter_id, vehicle_class_id, period_id, band_min, band_max,
     price, effective_from, effective_to, is_active, created_on)
SELECT u.underwriter_id, vc.vehicle_class_id, p.period_id, x.band_min, x.band_max,
       x.price, CURDATE(), NULL, 1, NOW()
FROM (VALUES
        -- ===== DEFINITE ASSURANCE (Ref DAC/MOTOR/0001/2024) =====
        -- Motor private: TPO 4,500 (annual)
        ROW('DEFINITE','PRIVATE',5,NULL,NULL,4500),
        -- Motor cycle non-PSV: 2,000 ; PSV: annual 3,500 / 6mo 2,000 / monthly 1,000
        ROW('DEFINITE','MOTORCYCLE:PRIVATE',11,NULL,NULL,2000),
        ROW('DEFINITE','MOTORCYCLE:PSV',12,NULL,NULL,3500),
        ROW('DEFINITE','MOTORCYCLE:PSV',6,NULL,NULL,2000),
        ROW('DEFINITE','MOTORCYCLE:PSV',3,NULL,NULL,1000),
        -- Tuk Tuk PSV: annual 4,500 / monthly 1,000
        ROW('DEFINITE','PSV-TAXI / TUK TUK',3,NULL,NULL,4500),
        ROW('DEFINITE','PSV-TAXI / TUK TUK',5,NULL,NULL,1000),
        -- Private Hire chauffeur/Taxi: <=9 5,500 / 10-17 8,500 / 18-25 12,500 / >25 15,500
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber',5,0,9,5500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber',5,9.01,17,8500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber',5,17.01,25,12500),
        ROW('DEFINITE','PSV-PRIVATE HIRE/Uber',5,25.01,NULL,15500),
        -- Own goods / general cartage hybrid: <=3t 5,500 / 3-8t 7,500 / >8t 9,500
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS',5,0,3,5500),
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS',5,3.01,8,7500),
        ROW('DEFINITE','MOTOR COMMERCIAL:OWN GOODS',5,8.01,NULL,9500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL',5,0,3,5500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL',5,3.01,8,7500),
        ROW('DEFINITE','MOTOR COMMERCIAL:GENERAL',5,8.01,NULL,9500),
        ROW('DEFINITE','MOTOR COMMERCIAL:Prime Mover',5,NULL,NULL,15000),
        ROW('DEFINITE','MOTOR COMMERCIAL:TRACTOR',5,NULL,NULL,3000),

        -- ===== MUA INSURANCE (May 2025) =====
        ROW('MUA','PRIVATE',5,NULL,NULL,12500),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS',5,0,3,15000),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS',5,3.01,8,20000),
        ROW('MUA','MOTOR COMMERCIAL:OWN GOODS',5,8.01,NULL,25000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL',5,0,8,25000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL',5,8.01,20,30000),
        ROW('MUA','MOTOR COMMERCIAL:GENERAL',5,20.01,30,35000),
        ROW('MUA','MOTOR COMMERCIAL:Prime Mover',5,NULL,NULL,30000),

        -- ===== KENYA ORIENT (KOIL 2024) =====
        ROW('KENYA_ORIENT','PRIVATE',5,NULL,NULL,7574),
        ROW('KENYA_ORIENT','MOTORCYCLE:PRIVATE',5,NULL,NULL,5000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:OWN GOODS',5,0,3,7500),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:OWN GOODS',5,3.01,8,12000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:GENERAL',5,8.01,20,20000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:GENERAL',5,20.01,30,25000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Prime Mover',5,NULL,NULL,20000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer',5,0,10,17500),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer',5,10.01,20,25000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer',5,20.01,30,30000),
        ROW('KENYA_ORIENT','MOTOR COMMERCIAL:Tankers & Specified Trailer',5,30.01,NULL,35000),

        -- ===== MONARCH (Motor Pricing 2025) =====
        ROW('MONARCH','MOTORCYCLE:PRIVATE',5,NULL,NULL,2000),
        ROW('MONARCH','MOTORCYCLE:PSV',5,NULL,NULL,3000),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,0,3.49,4500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,3.5,8.49,5500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,8.5,12.49,6500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,12.5,15.49,7500),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,15.5,20,10000),
        ROW('MONARCH','MOTOR COMMERCIAL:OWN GOODS',5,20.01,NULL,15000),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,0,3.49,4500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,3.5,8.49,5500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,8.5,12.49,6500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,12.5,15.49,7500),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,15.5,20,10000),
        ROW('MONARCH','MOTOR COMMERCIAL:GENERAL',5,20.01,NULL,15000),
        ROW('MONARCH','MOTOR COMMERCIAL:Prime Mover',5,NULL,NULL,10000),

        -- ===== PIONEER (Rates 2025) — School Bus TPO bands =====
        ROW('PIONEER','PSV-BUS',5,0,14,7500),
        ROW('PIONEER','PSV-BUS',5,14.01,25,12500),
        ROW('PIONEER','PSV-BUS',5,25.01,NULL,18000)
     ) AS x(uw_code, class_name, period_id, band_min, band_max, price)
JOIN Underwriters u ON u.code = x.uw_code
JOIN MotorVehicleClasses vc ON vc.name = x.class_name
JOIN Periods p ON p.period_id = x.period_id;


-- ---------------------------------------------------------------------
-- 6) RETIRE FABRICATED PLACEHOLDER RATES
--    Underwriters with no rate document in the current set only have
--    fabricated placeholders, which would otherwise compete with the real
--    partners. Deactivate (never delete) — fully reversible, and only
--    flips is_active.
-- ---------------------------------------------------------------------
-- 6a) No documented rates at all -> hide the underwriter entirely.
UPDATE Underwriters SET is_active = 0
 WHERE code IN ('HERITAGE','PACIS','KENINDIA');

-- 6b) Fabricated COMPREHENSIVE bands for underwriters whose docs give no
--     readable comprehensive private rates (Monarch keeps its real TPO).
UPDATE ComprehensiveRateBand rb
JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
   SET rb.is_active = 0
 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA','MONARCH');

-- To bring them back once real rates arrive:
--   UPDATE Underwriters SET is_active = 1 WHERE code IN ('HERITAGE','PACIS','KENINDIA');
--   UPDATE ComprehensiveRateBand rb JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
--     SET rb.is_active = 1 WHERE u.code IN ('HERITAGE','PACIS','KENINDIA','MONARCH');


-- =====================================================================
-- NOT SEEDED — needs confirmation (documented, not guessed):
--   * Heritage new motor private terms, APA 13-01-2026 revision and the
--     Fidelity private underwriting update are IMAGE-ONLY / unreadable, so
--     no figures could be extracted (need OCR or a typed copy).
--   * Monarch / Pioneer COMPREHENSIVE private rates: the rate tables did
--     not line up with their column headings in extraction, so no private
--     rate bands were seeded for them.
--   * Commercial / PSV COMPREHENSIVE: class-specific, cannot be expressed
--     by the value-band table — belongs in ComprehensiveRateFormula
--     (underwriter + vehicle_class + base rate + min premium).
--   * Short-term (weekly / 2-week / 6-month) TPO: most insurers state
--     "no short-term TPO only cover"; only periods a doc publishes were
--     seeded. Definite PSV capacity table (DAC/PSV/0002/2025) is the one
--     source with explicit 7/14/30-day PSV TPO — seed separately if wanted.
--   * The website TPO form sends no TONNAGE, so Commercial tonnage bands
--     above are usable from the Admin purchase wizard but not yet from the
--     public site (needs a tonnage input on the Details page).
-- =====================================================================
