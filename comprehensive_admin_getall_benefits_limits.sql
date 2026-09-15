USE insurance_platform;

DROP PROCEDURE IF EXISTS usp_ComprehensiveBenefit_GetAll;

DELIMITER $$
CREATE PROCEDURE usp_ComprehensiveBenefit_GetAll(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT b.benefit_id, b.underwriter_id, u.name AS underwriter_name,
               b.benefit_code, b.benefit_name, b.default_price,
               b.is_included_in_base, b.description, b.display_order, b.is_active
        FROM ComprehensiveBenefit b
        INNER JOIN Underwriters u ON u.underwriter_id = b.underwriter_id
        WHERE b.is_active = 1
        ORDER BY b.underwriter_id, b.display_order ASC, b.benefit_name ASC;
    ELSE
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT b.benefit_id, b.underwriter_id, u.name AS underwriter_name,
               b.benefit_code, b.benefit_name, b.default_price,
               b.is_included_in_base, b.description, b.display_order, b.is_active
        FROM ComprehensiveBenefit b
        INNER JOIN Underwriters u ON u.underwriter_id = b.underwriter_id
        WHERE b.underwriter_id = p_underwriter_id AND b.is_active = 1
        ORDER BY b.display_order ASC, b.benefit_name ASC;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS usp_ComprehensiveLiabilityLimit_GetAll;

DELIMITER $$
CREATE PROCEDURE usp_ComprehensiveLiabilityLimit_GetAll(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT l.liability_limit_id, l.underwriter_id, u.name AS underwriter_name,
               l.limit_name, l.limit_value, l.display_order
        FROM ComprehensiveLiabilityLimit l
        INNER JOIN Underwriters u ON u.underwriter_id = l.underwriter_id
        ORDER BY l.underwriter_id, l.display_order ASC, l.limit_name ASC;
    ELSE
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT l.liability_limit_id, l.underwriter_id, u.name AS underwriter_name,
               l.limit_name, l.limit_value, l.display_order
        FROM ComprehensiveLiabilityLimit l
        INNER JOIN Underwriters u ON u.underwriter_id = l.underwriter_id
        WHERE l.underwriter_id = p_underwriter_id
        ORDER BY l.display_order ASC, l.limit_name ASC;
    END IF;
END$$
DELIMITER ;
