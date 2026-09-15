-- Generated import for TpoPriceMapping - placeholder price=1 per underwriter instruction.
-- Real premiums to be set later via the same usp_TpoPriceMapping_SetPrice proc
-- (calling it again for the same underwriter+class+period+capacity/tonnage combo
-- supersedes the placeholder automatically - no manual cleanup needed).

USE insurance_platform;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-TAXI / TUK TUK'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '52', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '52', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '52', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '53', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '53', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '53', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '54', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '54', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '54', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '55', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '55', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '55', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '56', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '56', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '56', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '57', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '57', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '57', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '58', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '58', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '58', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '64', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '64', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '64', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '65', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '65', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '65', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '66', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '66', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '66', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '67', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '67', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '67', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '68', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '68', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '68', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '69', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '69', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '69', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '70', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '70', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '70', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 22, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 23, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 24, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 26, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 27, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 28, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 29, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 30, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-TAXI / TUK TUK'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-TAXI / TUK TUK'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '6 Months'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1.5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1.5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '59', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '60', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '61', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '62', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '63', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '59', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '59', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '60', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '60', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-PRIVATE HIRE/Uber'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '14', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 22, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 23, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 24, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 22, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 23, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 24, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 22, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 23, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 24, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Trailer'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 17, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 18, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 19, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 20, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 22, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 23, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 24, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 21, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '8', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '9', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '10', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '11', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '15', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '16', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '17', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '12', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '13', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '18', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '19', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '20', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '21', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '22', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '23', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '24', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '25', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '26', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '27', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '28', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '29', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '30', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '31', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '32', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '33', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '34', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-MATATU'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '35', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '36', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '37', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '38', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '39', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '40', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '41', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '42', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '43', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '44', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '45', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '46', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '47', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '48', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '49', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '50', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '2 Weeks'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-BUS'),
    (SELECT period_id FROM Periods WHERE name = '1 Week'),
    '51', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'K_ALLIANCE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'K_ALLIANCE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'K_ALLIANCE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'K_ALLIANCE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 25000, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 11, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:Prime Mover'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 12, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 13, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 14, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 15, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'TAKAFUL'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 16, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'AMACO'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PSV-TAXI / TUK TUK'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '1', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:OWN GOODS'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 10, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PSV'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTORCYCLE:PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 1, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 3, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 4, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 5, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 6, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 7, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 8, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DIRECTLINE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:TRACTOR'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 9, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'MOTOR COMMERCIAL:GENERAL'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    NULL, 2, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Month'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '2', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '3', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '5', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '4', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '6', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

CALL usp_TpoPriceMapping_SetPrice(
    (SELECT underwriter_id FROM Underwriters WHERE code = 'DEFINITE'),
    (SELECT vehicle_class_id FROM MotorVehicleClasses WHERE name = 'PRIVATE'),
    (SELECT period_id FROM Periods WHERE name = '1 Year'),
    '7', NULL, 1, CURDATE(), 1,
    @rc, @msg, @id); SELECT @rc, @msg, @id;

