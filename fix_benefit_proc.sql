USE insurance_platform;
DROP PROCEDURE IF EXISTS usp_ComprehensiveBenefit_GetList;
DELIMITER //
CREATE PROCEDURE usp_ComprehensiveBenefit_GetList(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    SET o_result_code = 0;
    SET o_result_message = 'Success';
    SELECT benefit_id, benefit_code, benefit_name, default_price, is_included_in_base, description, display_order
    FROM ComprehensiveBenefit
    WHERE underwriter_id = p_underwriter_id AND is_active = 1
    ORDER BY display_order ASC, benefit_name ASC;
END //
DELIMITER ;
