using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class UnderwriterCertificateRepository : IUnderwriterCertificateRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public UnderwriterCertificateRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public Task<StoredProcResult<UnderwriterCertPurchaseData?>> GetPurchaseDataAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };
        return _executor.ExecuteQuerySingleAsync("usp_UnderwriterCert_GetPurchaseData", parameters, MapPurchaseDataRow);
    }

    public async Task<StoredProcResult<long?>> CreateRequestAsync(
        long purchaseId, string integration, string externalRef, string status, string? requestPayload)
    {
        var requestIdParam = new MySqlParameter("o_request_id", MySqlDbType.Int64)
        {
            Direction = ParameterDirection.Output
        };

        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_integration", integration),
            new("p_external_ref", externalRef),
            new("p_status", status),
            new("p_request_payload", (object?)requestPayload ?? DBNull.Value),
            requestIdParam
        };

        var result = await _executor.ExecuteAsync("usp_UnderwriterCert_CreateRequest", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = requestIdParam.Value is null or DBNull ? null : Convert.ToInt64(requestIdParam.Value)
        };
    }

    public Task<StoredProcResult> UpdateRequestAsync(
        long requestId, string? status, string? responsePayload = null, string? callbackPayload = null,
        string? certNo = null, string? policyNo = null, string? certUrl = null, string? errorMessage = null)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_request_id", requestId),
            new("p_status", (object?)status ?? DBNull.Value),
            new("p_response_payload", (object?)responsePayload ?? DBNull.Value),
            new("p_callback_payload", (object?)callbackPayload ?? DBNull.Value),
            new("p_cert_no", (object?)certNo ?? DBNull.Value),
            new("p_policy_no", (object?)policyNo ?? DBNull.Value),
            new("p_cert_url", (object?)certUrl ?? DBNull.Value),
            new("p_error_message", (object?)Truncate(errorMessage, 500) ?? DBNull.Value)
        };

        return _executor.ExecuteAsync("usp_UnderwriterCert_UpdateRequest", parameters);
    }

    public Task<StoredProcResult<UnderwriterCertRequest?>> FindForCallbackAsync(
        string integration, string? externalRef, string? policyNumber)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_integration", integration),
            new("p_external_ref", (object?)externalRef ?? DBNull.Value),
            new("p_policy_number", (object?)policyNumber ?? DBNull.Value)
        };

        return _executor.ExecuteQuerySingleAsync("usp_UnderwriterCert_FindForCallback", parameters, MapRequestRow);
    }

    private static string? Truncate(string? value, int max) =>
        value is null || value.Length <= max ? value : value[..max];

    private static string? NullableString(MySqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetString(column);

    private static UnderwriterCertPurchaseData? MapPurchaseDataRow(MySqlDataReader reader)
    {
        return new UnderwriterCertPurchaseData
        {
            PurchaseId = reader.GetInt64("purchase_id"),
            PolicyNumber = NullableString(reader, "policy_number"),
            StartDate = reader.GetDateTime("start_date"),
            EndDate = reader.GetDateTime("end_date"),
            PremiumAmount = reader.GetDecimal("premium_amount"),
            NtsaCertificateNo = NullableString(reader, "ntsa_certificate_no"),
            PaymentStatus = NullableString(reader, "payment_status"),
            DurationDays = Convert.ToInt32(reader["duration_days"]),
            Policyholder = NullableString(reader, "policyholder"),
            IdNo = NullableString(reader, "id_no"),
            ClientPhone = NullableString(reader, "client_phone"),
            ClientEmail = NullableString(reader, "client_email"),
            KraPin = NullableString(reader, "kra_pin"),
            RegNo = NullableString(reader, "reg_no"),
            Make = NullableString(reader, "make"),
            Model = NullableString(reader, "model"),
            ChassisNo = NullableString(reader, "chassis_no"),
            EngineNo = NullableString(reader, "engine_no"),
            YearOfManufacture = reader.IsDBNull(reader.GetOrdinal("yearofmanufacture")) ? null : reader.GetInt32("yearofmanufacture"),
            PBodyType = NullableString(reader, "p_bodytype"),
            VehicleType = NullableString(reader, "vehicle_type"),
            CubicCapacity = NullableString(reader, "cubiccapacity"),
            VehicleValue = reader.IsDBNull(reader.GetOrdinal("vehicle_value")) ? null : reader.GetDecimal("vehicle_value"),
            Tonnage = reader.IsDBNull(reader.GetOrdinal("tonnage")) ? null : reader.GetDecimal("tonnage"),
            LicensedToCarry = reader.IsDBNull(reader.GetOrdinal("licensedtocarry")) ? null : reader.GetInt64("licensedtocarry"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = NullableString(reader, "underwriter_name")
        };
    }

    private static UnderwriterCertRequest MapRequestRow(MySqlDataReader reader)
    {
        return new UnderwriterCertRequest
        {
            RequestId = reader.GetInt64("request_id"),
            PurchaseId = reader.GetInt64("purchase_id"),
            Integration = reader.GetString("integration"),
            ExternalRef = reader.GetString("external_ref"),
            Status = reader.GetString("status"),
            CertNo = NullableString(reader, "cert_no")
        };
    }
}
