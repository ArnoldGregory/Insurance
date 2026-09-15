using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class OtpRepository : IOtpRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public OtpRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(string targetType, long targetId, string destination, string purpose, string otpCodeHash, int expiresMinutes)
    {
        
        var otpIdParam = new MySqlParameter("o_otp_id", MySqlDbType.Int64)
        {
            Direction = ParameterDirection.Output
        };

        var parameters = new List<MySqlParameter>
        {
            new("p_target_type", targetType),
            new("p_target_id", targetId),
            new("p_destination", destination),
            new("p_purpose", purpose),
            new("p_otp_code_hash", otpCodeHash),
            new("p_expires_minutes", expiresMinutes),
            otpIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Otp_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = ReadNullableLong(otpIdParam)
        };
    }

    public async Task<StoredProcResult<long?>> VerifyAsync(string targetType, long targetId, string purpose, string otpCodeHash)
    {
        var otpIdParam = new MySqlParameter("o_otp_id", MySqlDbType.Int64)
        {
            Direction = ParameterDirection.Output
        };

        var parameters = new List<MySqlParameter>
        {
            new("p_target_type", targetType),
            new("p_target_id", targetId),
            new("p_purpose", purpose),
            new("p_otp_code_hash", otpCodeHash),
            otpIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Otp_Verify", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = ReadNullableLong(otpIdParam)
        };
    }

    private static long? ReadNullableLong(MySqlParameter parameter)
    {
        return parameter.Value is null or DBNull ? null : Convert.ToInt64(parameter.Value);
    }
}
