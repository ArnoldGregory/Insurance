using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class UnderwriterRepository : IUnderwriterRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public UnderwriterRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(string name, string code, string? contactEmail, string? contactPhone, long actorId)
    {
        var underwriterIdParam = new MySqlParameter("o_underwriter_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_name", name),
            new("p_code", code),
            new("p_contact_email", (object?)contactEmail ?? DBNull.Value),
            new("p_contact_phone", (object?)contactPhone ?? DBNull.Value),
            new("p_actor_id", actorId),
            underwriterIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Underwriter_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = underwriterIdParam.Value is null or DBNull ? null : Convert.ToInt64(underwriterIdParam.Value)
        };
    }

    public Task<StoredProcResult<Underwriter?>> GetByIdAsync(long underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", underwriterId) };
        return _executor.ExecuteQuerySingleAsync("usp_Underwriter_GetById", parameters, MapRow);
    }

    public Task<StoredProcResult<List<UnderwriterSummary>>> GetListAsync(bool? activeOnly)
    {
        // p_active_only is declared INT in the proc (1/0/NULL), not
        // TINYINT(1) like the table column - passed through as an int here
        // to match exactly rather than relying on an implicit bool->int
        // conversion at the MySqlConnector layer.
        var parameters = new List<MySqlParameter>
        {
            new("p_active_only", activeOnly is null ? DBNull.Value : (activeOnly.Value ? 1 : 0))
        };

        return _executor.ExecuteQueryAsync("usp_Underwriter_GetList", parameters, MapSummaryRow);
    }

    public Task<StoredProcResult> UpdateAsync(long underwriterId, string? name, string? contactEmail, string? contactPhone, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_name", (object?)name ?? DBNull.Value),
            new("p_contact_email", (object?)contactEmail ?? DBNull.Value),
            new("p_contact_phone", (object?)contactPhone ?? DBNull.Value),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Underwriter_Update", parameters);
    }

    public Task<StoredProcResult> SetActiveStatusAsync(long underwriterId, bool isActive, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_is_active", isActive),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Underwriter_SetActiveStatus", parameters);
    }

    public Task<StoredProcResult> SetPolicyTypeAsync(long underwriterId, string policyType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_policy_type", policyType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Underwriter_SetPolicyType", parameters);
    }

    private static Underwriter MapRow(MySqlDataReader reader)
    {
        return new Underwriter
        {
            UnderwriterId = reader.GetInt64("underwriter_id"),
            Name = reader.GetString("name"),
            Code = reader.GetString("code"),
            ContactEmail = reader.IsDBNull(reader.GetOrdinal("contact_email")) ? null : reader.GetString("contact_email"),
            ContactPhone = reader.IsDBNull(reader.GetOrdinal("contact_phone")) ? null : reader.GetString("contact_phone"),
            IsActive = reader.GetBoolean("is_active"),
            DmvicCode = reader.IsDBNull(reader.GetOrdinal("dmvic_code")) ? null : reader.GetString("dmvic_code"),
            PolicyType = reader.GetString("policy_type"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static UnderwriterSummary MapSummaryRow(MySqlDataReader reader)
    {
        return new UnderwriterSummary
        {
            UnderwriterId = reader.GetInt64("underwriter_id"),
            Name = reader.GetString("name"),
            Code = reader.GetString("code"),
            ContactEmail = reader.IsDBNull(reader.GetOrdinal("contact_email")) ? null : reader.GetString("contact_email"),
            ContactPhone = reader.IsDBNull(reader.GetOrdinal("contact_phone")) ? null : reader.GetString("contact_phone"),
            IsActive = reader.GetBoolean("is_active"),
            PolicyType = reader.GetString("policy_type"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }
}
