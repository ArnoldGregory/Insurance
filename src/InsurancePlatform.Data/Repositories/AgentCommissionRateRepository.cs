using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class AgentCommissionRateRepository : IAgentCommissionRateRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public AgentCommissionRateRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> SetAsync(long agentUserId, decimal ratePercent, DateTime? effectiveFrom, long setByUserId)
    {
        var rateIdParam = new MySqlParameter("o_rate_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_agent_user_id", agentUserId),
            new("p_rate_percent", ratePercent),
            new("p_effective_from", (object?)effectiveFrom ?? DBNull.Value),
            new("p_set_by_user_id", setByUserId),
            rateIdParam
        };

        var result = await _executor.ExecuteAsync("usp_AgentCommissionRate_Set", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = rateIdParam.Value is null or DBNull ? null : Convert.ToInt64(rateIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<AgentCommissionRate>>> GetListByAgentAsync(long agentUserId)
    {
        var parameters = new List<MySqlParameter> { new("p_agent_user_id", agentUserId) };
        return _executor.ExecuteQueryAsync("usp_AgentCommissionRate_GetListByAgent", parameters, MapRow);
    }

    private static AgentCommissionRate MapRow(MySqlDataReader reader)
    {
        return new AgentCommissionRate
        {
            RateId = reader.GetInt64("rate_id"),
            AgentUserId = reader.GetInt64("agent_user_id"),
            RatePercent = reader.GetDecimal("rate_percent"),
            EffectiveFrom = reader.GetDateTime("effective_from"),
            EffectiveTo = reader.IsDBNull(reader.GetOrdinal("effective_to")) ? null : reader.GetDateTime("effective_to"),
            SetByUserId = reader.GetInt64("set_by_user_id"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }
}
