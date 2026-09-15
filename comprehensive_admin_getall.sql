USE insurance_platform;

DROP PROCEDURE IF EXISTS usp_ComprehensiveRateBand_GetAll;

DELIMITER $$
CREATE PROCEDURE usp_ComprehensiveRateBand_GetAll(
    IN p_underwriter_id BIGINT UNSIGNED,
    OUT o_result_code   INT,
    OUT o_result_message VARCHAR(500)
)
BEGIN
    IF p_underwriter_id IS NULL THEN
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT rb.band_id, rb.underwriter_id, u.name AS underwriter_name,
               rb.value_min, rb.value_max, rb.rate_percent, rb.min_premium,
               rb.effective_from, rb.effective_to, rb.is_active
        FROM ComprehensiveRateBand rb
        INNER JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
        ORDER BY rb.underwriter_id, rb.value_min ASC;
    ELSE
        SET o_result_code = 0;
        SET o_result_message = 'Success';
        SELECT rb.band_id, rb.underwriter_id, u.name AS underwriter_name,
               rb.value_min, rb.value_max, rb.rate_percent, rb.min_premium,
               rb.effective_from, rb.effective_to, rb.is_active
        FROM ComprehensiveRateBand rb
        INNER JOIN Underwriters u ON u.underwriter_id = rb.underwriter_id
        WHERE rb.underwriter_id = p_underwriter_id
        ORDER BY rb.value_min ASC;
    END IF;
END$$
DELIMITER ;
