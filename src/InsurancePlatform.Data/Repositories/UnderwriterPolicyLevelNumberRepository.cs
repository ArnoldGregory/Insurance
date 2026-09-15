using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class UnderwriterPolicyLevelNumberRepository : IUnderwriterPolicyLevelNumberRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public UnderwriterPolicyLevelNumberRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> SetAsync(long underwriterId, int policyLevelId, string policyNumber, long actorId)
    {
        var idParam = new MySqlParameter("o_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_policy_level_id", policyLevelId),
            new("p_policy_number", policyNumber),
            new("p_actor_id", actorId),
            idParam
        };

        var result = await _executor.ExecuteAsync("usp_UnderwriterPolicyLevelNumber_Set", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = idParam.Value is null or DBNull ? null : Convert.ToInt64(idParam.Value)
        };
    }

    public Task<StoredProcResult<List<UnderwriterPolicyLevelNumber>>> GetListAsync(long? underwriterId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value)
        };

        return _executor.ExecuteQueryAsync("usp_UnderwriterPolicyLevelNumber_GetList", parameters, MapRow);
    }

    private static UnderwriterPolicyLevelNumber MapRow(MySqlDataReader reader)
    {
        return new UnderwriterPolicyLevelNumber
        {
            Id = reader.GetInt64("id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            PolicyType = reader.GetString("policy_type"),
            PolicyLevelId = reader.GetInt32("policy_level_id"),
            PolicyNumber = reader.GetString("policy_number"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }
}
