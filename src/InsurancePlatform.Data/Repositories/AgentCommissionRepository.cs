using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class AgentCommissionRepository : IAgentCommissionRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public AgentCommissionRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> AccrueAsync(long purchaseId, long agentUserId, long actorId)
    {
        var commissionIdParam = new MySqlParameter("o_commission_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_agent_user_id", agentUserId),
            new("p_actor_id", actorId),
            commissionIdParam
        };

        var result = await _executor.ExecuteAsync("usp_AgentCommission_Accrue", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = commissionIdParam.Value is null or DBNull ? null : Convert.ToInt64(commissionIdParam.Value)
        };
    }

    public async Task<StoredProcResult<AgentCommissionListPage>> GetListByAgentAsync(long agentUserId, string? status, int pageNumber, int pageSize)
    {
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_agent_user_id", agentUserId),
            new("p_status", (object?)status ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        var result = await _executor.ExecuteQueryAsync("usp_AgentCommission_GetListByAgent", parameters, MapCommissionRow);

        var page = new AgentCommissionListPage
        {
            TotalCount = totalCountParam.Value is null or DBNull ? 0 : Convert.ToInt64(totalCountParam.Value),
            Items = result.Data ?? new List<AgentCommission>()
        };

        return new StoredProcResult<AgentCommissionListPage>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = page
        };
    }

    public async Task<StoredProcResult<decimal>> GetAvailableBalanceAsync(long agentUserId)
    {
        var balanceParam = new MySqlParameter("o_available_balance", MySqlDbType.Decimal) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_agent_user_id", agentUserId),
            balanceParam
        };

        var result = await _executor.ExecuteAsync("usp_AgentCommission_GetAvailableBalance", parameters);

        return new StoredProcResult<decimal>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = balanceParam.Value is null or DBNull ? 0 : Convert.ToDecimal(balanceParam.Value)
        };
    }

    public async Task<StoredProcResult<CommissionWithdrawalRequestResult?>> RequestWithdrawalAsync(long agentUserId)
    {
        var withdrawalIdParam = new MySqlParameter("o_withdrawal_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var amountParam = new MySqlParameter("o_amount", MySqlDbType.Decimal) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_agent_user_id", agentUserId),
            withdrawalIdParam,
            amountParam
        };

        var result = await _executor.ExecuteAsync("usp_CommissionWithdrawal_Request", parameters);

        CommissionWithdrawalRequestResult? requestResult = null;
        if (result.IsSuccess)
        {
            requestResult = new CommissionWithdrawalRequestResult
            {
                WithdrawalId = Convert.ToInt64(withdrawalIdParam.Value),
                Amount = Convert.ToDecimal(amountParam.Value)
            };
        }

        return new StoredProcResult<CommissionWithdrawalRequestResult?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = requestResult
        };
    }

    public Task<StoredProcResult> UpdateWithdrawalStatusAsync(long withdrawalId, string status, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_withdrawal_id", withdrawalId),
            new("p_status", status),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_CommissionWithdrawal_UpdateStatus", parameters);
    }

    public Task<StoredProcResult<List<CommissionWithdrawal>>> GetWithdrawalListByAgentAsync(long agentUserId)
    {
        var parameters = new List<MySqlParameter> { new("p_agent_user_id", agentUserId) };
        return _executor.ExecuteQueryAsync("usp_CommissionWithdrawal_GetListByAgent", parameters, MapWithdrawalRow);
    }

    public Task<StoredProcResult<List<CommissionWithdrawalQueueItem>>> GetPendingWithdrawalsAsync()
    {
        return _executor.ExecuteQueryAsync("usp_CommissionWithdrawal_GetPendingList", Array.Empty<MySqlParameter>(), MapQueueItemRow);
    }

    public async Task<StoredProcResult<AgentCommissionDashboardSummary>> GetSummaryAsync()
    {
        // No IN params at all - a platform-wide rollup, same shape as
        // usp_QuoteRequest_GetSummary's own no-param call.
        var result = await _executor.ExecuteQuerySingleAsync(
            "usp_AgentCommission_GetSummary", new List<MySqlParameter>(), MapSummaryStatsRow);

        return new StoredProcResult<AgentCommissionDashboardSummary>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new AgentCommissionDashboardSummary()
        };
    }

    private static AgentCommissionDashboardSummary MapSummaryStatsRow(MySqlDataReader reader)
    {
        return new AgentCommissionDashboardSummary
        {
            TotalAccrued = Convert.ToDecimal(reader["total_accrued"]),
            TotalWithdrawn = Convert.ToDecimal(reader["total_withdrawn"]),
            AvailableBalance = Convert.ToDecimal(reader["available_balance"]),
            PendingWithdrawalCount = Convert.ToInt64(reader["pending_withdrawal_count"]),
            PendingWithdrawalAmount = Convert.ToDecimal(reader["pending_withdrawal_amount"])
        };
    }

    private static AgentCommission MapCommissionRow(MySqlDataReader reader)
    {
        return new AgentCommission
        {
            CommissionId = reader.GetInt64("commission_id"),
            PurchaseId = reader.GetInt64("purchase_id"),
            PolicyNumber = reader.IsDBNull(reader.GetOrdinal("policy_number")) ? null : reader.GetString("policy_number"),
            RatePercentApplied = reader.GetDecimal("rate_percent_applied"),
            CoverAmount = reader.GetDecimal("cover_amount"),
            CommissionAmount = reader.GetDecimal("commission_amount"),
            Status = reader.GetString("status"),
            WithdrawalId = reader.IsDBNull(reader.GetOrdinal("withdrawal_id")) ? null : reader.GetInt64("withdrawal_id"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static CommissionWithdrawal MapWithdrawalRow(MySqlDataReader reader)
    {
        return new CommissionWithdrawal
        {
            WithdrawalId = reader.GetInt64("withdrawal_id"),
            AgentUserId = reader.GetInt64("agent_user_id"),
            Amount = reader.GetDecimal("amount"),
            Status = reader.GetString("status"),
            RequestedOn = reader.GetDateTime("requested_on"),
            ProcessedByUserId = reader.IsDBNull(reader.GetOrdinal("processed_by_user_id")) ? null : reader.GetInt64("processed_by_user_id"),
            ProcessedOn = reader.IsDBNull(reader.GetOrdinal("processed_on")) ? null : reader.GetDateTime("processed_on")
        };
    }

    private static CommissionWithdrawalQueueItem MapQueueItemRow(MySqlDataReader reader)
    {
        return new CommissionWithdrawalQueueItem
        {
            WithdrawalId = reader.GetInt64("withdrawal_id"),
            AgentUserId = reader.GetInt64("agent_user_id"),
            AgentName = reader.GetString("agent_name"),
            Amount = reader.GetDecimal("amount"),
            Status = reader.GetString("status"),
            RequestedOn = reader.GetDateTime("requested_on")
        };
    }
}
