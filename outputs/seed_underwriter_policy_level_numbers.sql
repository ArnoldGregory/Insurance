-- Run against the live DB, after UnderwriterPolicyLevelNumber + PolicyLevels
-- exist (see the two prior migration scripts). Resolves underwriter_id by
-- code so you don't have to know/guess the actual auto-increment values.
-- Dedupes the two identical rows (11/12, both HDO/0806/000161/2025, level 5)
-- from your legacy dump into one call.

USE insurance_platform;

-- ===================== Monarch (legacy company_id = 4) =====================
-- No level 1 (Class A - PSV Unmarked) number on file for Monarch - not called.

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'MONARCH'),
    3, 'HDO/0700/521017/2024', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'MONARCH'),
    2, 'HDO/0800/010468/2024', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'MONARCH'),
    4, 'HDO/0701/006632/2024', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'MONARCH'),
    6, 'HDO/0810/037723/2024', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'MONARCH'),
    5, 'HDO/0806/000161/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

-- ===================== Definite (legacy company_id = 8) =====================

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    3, 'DA/0700/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    2, 'DA/0800/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    1, 'DA/0906/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    5, 'DA/0904/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    4, 'DA/0701/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_UnderwriterPolicyLevelNumber_Set(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    6, 'DA/0703/000500/2025', 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

-- After running, verify with:
-- SELECT n.id, u.name, u.code, n.policy_level_id, pl.name AS level_name, n.policy_number
-- FROM UnderwriterPolicyLevelNumber n
-- JOIN Underwriters u ON u.underwriter_id = n.underwriter_id
-- JOIN PolicyLevels pl ON pl.policy_level_id = n.policy_level_id
-- WHERE u.code IN ('MONARCH','DEFINITE')
-- ORDER BY u.code, n.policy_level_id;
