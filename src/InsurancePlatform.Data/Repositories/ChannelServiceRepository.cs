using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class ChannelServiceRepository : IChannelServiceRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public ChannelServiceRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public Task<StoredProcResult<ChannelServiceAccount?>> GetByChannelAsync(string channel)
    {
        var parameters = new List<MySqlParameter> { new("p_channel", channel) };
        return _executor.ExecuteQuerySingleAsync("usp_ChannelServiceAccount_GetByChannel", parameters, MapRow);
    }

    public async Task<StoredProcResult<long?>> CreateAsync(string channel, string apiKeyHash, string? allowedIpRange, long actorId)
    {
        var serviceAccountIdParam = new MySqlParameter("o_service_account_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_channel", channel),
            new("p_api_key_hash", apiKeyHash),
            new("p_allowed_ip_range", (object?)allowedIpRange ?? DBNull.Value),
            new("p_actor_id", actorId),
            serviceAccountIdParam
        };

        var result = await _executor.ExecuteAsync("usp_ChannelServiceAccount_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = serviceAccountIdParam.Value is null or DBNull ? null : Convert.ToInt64(serviceAccountIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<ChannelServiceAccountSummary>>> GetListAsync()
    {
        return _executor.ExecuteQueryAsync("usp_ChannelServiceAccount_GetList", new List<MySqlParameter>(), MapSummaryRow);
    }

    public Task<StoredProcResult> SetStatusAsync(long serviceAccountId, bool isActive, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_service_account_id", serviceAccountId),
            new("p_is_active", isActive),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_ChannelServiceAccount_SetStatus", parameters);
    }

    public Task<StoredProcResult> RegenerateKeyAsync(long serviceAccountId, string newApiKeyHash, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_service_account_id", serviceAccountId),
            new("p_new_api_key_hash", newApiKeyHash),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_ChannelServiceAccount_RegenerateKey", parameters);
    }

    private static ChannelServiceAccount MapRow(MySqlDataReader reader)
    {
        return new ChannelServiceAccount
        {
            ServiceAccountId = reader.GetInt64("service_account_id"),
            Channel = reader.GetString("channel"),
            ApiKeyHash = reader.GetString("api_key_hash"),
            AllowedIpRange = reader.IsDBNull(reader.GetOrdinal("allowed_ip_range")) ? null : reader.GetString("allowed_ip_range"),
            RoleId = reader.GetInt64("role_id"),
            RoleCode = reader.GetString("role_code")
        };
    }

    private static ChannelServiceAccountSummary MapSummaryRow(MySqlDataReader reader)
    {
        return new ChannelServiceAccountSummary
        {
            ServiceAccountId = reader.GetInt64("service_account_id"),
            Channel = reader.GetString("channel"),
            AllowedIpRange = reader.IsDBNull(reader.GetOrdinal("allowed_ip_range")) ? null : reader.GetString("allowed_ip_range"),
            IsActive = reader.GetBoolean("is_active"),
            RoleCode = reader.GetString("role_code")
        };
    }
}
